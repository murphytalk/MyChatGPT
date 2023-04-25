import 'package:dart_openai/openai.dart';
import 'package:flutter/cupertino.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:my_chat_gpt/env/env.dart';
import 'package:my_chat_gpt/utils.dart';

@immutable
class User{
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
}

abstract class IStorage{
  Future<bool> connect();
  Future<void> close();
  Future<String> newConversation(List<String> tags, String owner, String topic);
  Future<bool> question(String msg);
  Future<bool> answer(OpenAIChatCompletionModel msg);
  Future<List<User>> getUsers();
}

class MongoDbStorage implements IStorage{
  static const _settings = 'settings';
  static const _name = 'name';
  static const _app = 'app';
  static const _users = 'users';

  static const _collectionName = 'QA';
  static const _tags = 'tags';
  static const _owner = 'owner';
  static const _topic = 'topic';
  static const _fromAi = 'from_ai';
  static const _uuid = 'uuid';
  static const _question = 'question';
  static const _answer = 'answer';
  static const _created = 'created';
  static const _messages = 'messages';

  late String _uuidStr;
  late Db _db;
  late DbCollection _collection;
  late DbCollection _settingsCollection;

  final Set<String> _knownTags = {};

  @override
  Future<String> newConversation(List<String> tags, String owner, String topic) async{
    _uuidStr = const Uuid().v1();
    var doc = {_uuid: _uuidStr , _tags: tags, _owner: owner, _topic: topic,
      _created: DateTime.now().microsecondsSinceEpoch,
      _messages: []
    };
    var r = await _collection.insertOne(doc);
    log('new conversation save result: ${r.isSuccess}');
    saveTags(false, tags.toSet());
    return _uuidStr;
  }

  Future<void> saveTags(bool updateDocTags, Set<String> tags) async{
    if(tags.isEmpty) return Future.value();

    if(updateDocTags) {
      var q = where.eq(_uuid, _uuidStr);
      var u = modify.set(_tags, tags.toList());
      var r = await _collection.updateOne(q, u);
      log('Updated $_uuidStr tags : $r');
    }

    var diff = tags.difference(_knownTags);
    if(diff.isEmpty){
      log("All tags are known");
    }
    else{
      log("Saving new tags $diff");
      _knownTags.addAll(diff);
      var q = where.eq(_name, _app);
      var app = await _settingsCollection.findOne(q);
      if(app != null){
        var u = modify.set(_tags, diff.toList());
        await _settingsCollection.update(q, u);
      }
      else{
        await _settingsCollection.insertOne({_name: _app, _tags: diff.toList()});
      }
    }
  }

  Future<bool> _saveMessage(Map<String, dynamic> payload) async{
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
    _db = await Db.create(Env.mongoDbConnStr);
    await _db.open() ;
    _collection = _db.collection(_collectionName);
    _settingsCollection = _db.collection(_settings);
    return _db.isConnected;
  }

  @override
  Future<bool> question(String msg){
    return _saveMessage({_fromAi: false, _question: msg});
  }

  @override
  Future<bool> answer(OpenAIChatCompletionModel msg) {
    return _saveMessage({_fromAi: true, _answer: msg.toMap()});
  }

  @override
  Future<List<User>> getUsers() async{
    try {
      var q = where.eq(_name, "users");
      var doc = await _settingsCollection.findOne(q);
      if(doc == null) return Future.error(Exception("No user settings"));
      var users = doc[_users] as Map<String, dynamic>;
      return users.entries.map((e) => User.fromMap(e.key, e.value)).toList(growable: false);
    }
    catch(e) {
      return Future.error(e);
    }
  }
}