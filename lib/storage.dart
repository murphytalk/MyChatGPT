import 'package:dart_openai/openai.dart';
import 'package:flutter/cupertino.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:my_chat_gpt/env/env.dart';
import 'package:my_chat_gpt/utils.dart';

abstract class Serializable {
  Map<String, dynamic> toMap();
}

@immutable
class User implements Serializable {
  final String name;
  final String fullName;
  const User({required this.name, required this.fullName});

  @override
  String toString() {
    return 'User{name: $name, fullName: $fullName}';
  }

  factory User.fromMap(String userName, Map<String, dynamic> json) {
    return User(name: userName, fullName: json['name']);
  }
  factory User.defaultUser() {
    return const User(name: "default", fullName: "Default User");
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      name: {_name: fullName}
    };
  }
}

class Config implements Serializable {
  // only conversation that has no less than this number messages will be shown in history
  // 0 means to show all conversations
  int minMsgNumOfConversationShownInHistory;
  Config({required this.minMsgNumOfConversationShownInHistory});

  factory Config.defaultCfg() {
    return Config(minMsgNumOfConversationShownInHistory: 1);
  }

  static const _minMsgNumOfConversationShownInHistory = 'minMsg';

  factory Config.fromMap(Map<String, dynamic> json) {
    return Config(
        minMsgNumOfConversationShownInHistory:
            json[_minMsgNumOfConversationShownInHistory]);
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      _minMsgNumOfConversationShownInHistory:
          minMsgNumOfConversationShownInHistory
    };
  }
}

@immutable
class Message {
  final bool fromAI;
  final String content;
  const Message({required this.fromAI, required this.content});
}

@immutable
class ConversationInfo {
  final String uuid;
  final String topic;
  const ConversationInfo({required this.uuid, required this.topic});
  bool get isEmpty => uuid == '';
  bool get isNotEmpty => !isEmpty;
  factory ConversationInfo.empty() {
    return const ConversationInfo(uuid: "", topic: "");
  }
}

const _name = 'name';
const _tags = 'tags';
const _owner = 'owner';
const _topic = 'topic';
const _fromAI = 'from_ai';
const _uuid = 'uuid';
const _question = 'question';
const _answer = 'answer';
const _created = 'created';
const _messages = 'messages';
const _users = 'users';
const _config = 'config';

class Conversation {
  final String uuid;
  final List<String> tags;
  final String owner;
  final DateTime created;
  final List<Message> messages;
  DateTime lastUpdated;
  String topic;

  Conversation(
      {required this.uuid,
      required this.topic,
      required this.tags,
      required this.owner,
      required this.created,
      required this.messages})
      : lastUpdated = created;

  factory Conversation.fromMap(
    Map<String, dynamic> json,
  ) {
    final List<Message> messages = [];
    json[_messages].forEach((m) {
      final isFromAi = m[_fromAI];
      String content;
      if (isFromAi) {
        content = m[_answer]['choices'][0]['message']['content'];
      } else {
        content = m[_question];
      }
      messages.add(Message(fromAI: isFromAi, content: content));
    });
    final tags = (json[_tags] as List<dynamic>)
        .map((e) => e.toString())
        .toList(growable: false);
    return Conversation(
        uuid: json[_uuid],
        topic: json[_topic],
        tags: tags,
        owner: json[_owner],
        created: _toDateTime(json[_created]),
        messages: messages);
  }

  static DateTime _toDateTime(dynamic input) {
    final i = input.toInt();
    return DateTime.fromMicrosecondsSinceEpoch(i);
  }
}

abstract class IStorage {
  Future<bool> connect();
  Future<void> close();
  Future<String> newConversation(List<String> tags, String owner, String topic);
  void resumeConversation(String uuid);
  Future<bool> question(String msg);
  Future<bool> answer(OpenAIChatCompletionModel msg);
  Future<List<User>> getUsers();
  Future<List<ConversationInfo>> getHistory(
      User user, int minMsg, int limit, int skip);
  Future<Conversation> getConversation(String uuid);
  Future<Config> getConfig();
  Future<void> saveConfig();
}

class MongoDbStorage implements IStorage {
  static const _settings = 'settings';
  static const _app = 'app';

  static const _collectionName = 'QA';

  late String _uuidStr;
  late Db _db;
  late DbCollection _collection;
  late DbCollection _settingsCollection;
  bool connected = false;

  final Set<String> _knownTags = {};

  @override
  Future<String> newConversation(
      List<String> tags, String owner, String topic) async {
    _uuidStr = const Uuid().v1();
    var doc = {
      _uuid: _uuidStr,
      _tags: tags,
      _owner: owner,
      _topic: topic,
      _created: DateTime.now().microsecondsSinceEpoch,
      _messages: []
    };
    var r = await _collection.insertOne(doc);
    log('new conversation save result: ${r.isSuccess}');
    saveTags(false, tags.toSet());
    return _uuidStr;
  }

  @override
  void resumeConversation(String uuid) {
    _uuidStr = uuid;
  }

  Future<void> saveTags(bool updateDocTags, Set<String> tags) async {
    if (tags.isEmpty) return Future.value();

    if (updateDocTags) {
      var q = where.eq(_uuid, _uuidStr);
      var u = modify.set(_tags, tags.toList());
      var r = await _collection.updateOne(q, u);
      log('Updated $_uuidStr tags : $r');
    }

    var diff = tags.difference(_knownTags);
    if (diff.isEmpty) {
      log("All tags are known");
    } else {
      log("Saving new tags $diff");
      _knownTags.addAll(diff);
      var q = where.eq(_name, _app);
      var app = await _settingsCollection.findOne(q);
      if (app != null) {
        var u = modify.set(_tags, diff.toList());
        await _settingsCollection.update(q, u);
      } else {
        await _settingsCollection
            .insertOne({_name: _app, _tags: diff.toList()});
      }
    }
  }

  Future<bool> _saveMessage(Map<String, dynamic> payload) async {
    var q = where.eq(_uuid, _uuidStr);
    var u = modify.push(_messages, payload);
    var r = await _collection.updateOne(q, u);
    log('Added new msg to conversation $_uuidStr, result: ${r.isSuccess}');
    return r.isSuccess;
  }

  @override
  Future<void> close() async {
    log('Disconnecting from db');
    await _db.close();
  }

  @override
  Future<bool> connect() async {
    if (!connected) {
      _db = await Db.create(Env.mongoDbConnStr);
      await _db.open();
      _collection = _db.collection(_collectionName);
      _settingsCollection = _db.collection(_settings);
      connected = _db.isConnected;
    }
    return connected;
  }

  @override
  Future<bool> question(String msg) {
    return _saveMessage({_fromAI: false, _question: msg});
  }

  @override
  Future<bool> answer(OpenAIChatCompletionModel msg) {
    return _saveMessage({_fromAI: true, _answer: msg.toMap()});
  }

  @override
  Future<List<User>> getUsers() async {
    try {
      var q = where.eq(_name, _users);
      var doc = await _settingsCollection.findOne(q);
      if (doc == null) {
        //first time to run this app, create a default user
        final u = User.defaultUser();
        await _settingsCollection.insertOne({_name: _users, _users: u.toMap()});
        return [u];
      } else {
        var users = doc[_users] as Map<String, dynamic>;
        return users.entries
            .map((e) => User.fromMap(e.key, e.value))
            .toList(growable: false);
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<Config> getConfig() async {
    try {
      var q = where.eq(_name, _config);
      var doc = await _settingsCollection.findOne(q);
      if (doc == null) {
        //first time to run this app, create a default config
        final c = Config.defaultCfg();
        await _settingsCollection
            .insertOne({_name: _config, _config: c.toMap()});
        return c;
      } else {
        return Config.fromMap(doc[_config]);
      }
    } catch (e) {
      return Future.error(e);
    }
  }

  @override
  Future<void> saveConfig() async {}

  @override
  Future<List<ConversationInfo>> getHistory(
      User user, int minMsg, int limit, int skip) async {
    final q = _collection.find(where
        .eq(_owner, user.name)
        .fields([_uuid, _topic])
        .sortBy('created', descending: true)
        .limit(limit)
        .skip(skip));
    return await q
        .map((e) => ConversationInfo(
            uuid: e[_uuid] as String, topic: e[_topic] as String))
        .toList();
  }

  @override
  Future<Conversation> getConversation(String uuid) async {
    final q = where.eq(_uuid, uuid);
    var doc = await _collection.findOne(q);
    if (doc == null) throw Exception('No such conversation');
    return Conversation.fromMap(doc);
  }
}
