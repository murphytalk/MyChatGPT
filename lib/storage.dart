import 'package:dart_openai/openai.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:my_chat_gpt/env/env.dart';
import 'package:my_chat_gpt/utils.dart';


abstract class IStorage{
  Future<bool> connect();
  Future<void> close();
  String newConversation(List<String> tags, String owner, String topic);
  Future<void> question(String msg);
  Future<void> answer(OpenAIChatCompletionModel msg);
}

class MongoDbStorage implements IStorage{
  static const _settingsCollectionName = 'settings';
  static const _settingsName = 'name';
  static const _settingsApp = 'app';

  static const _collectionName = 'QA';
  static const _tags = 'tags';
  static const _owner = 'owner';
  static const _topic = 'topic';
  static const _fromAi = 'from_ai';
  static const _meta = 'meta';
  static const _uuid = 'uuid';
  static const _question = 'question';
  static const _answer = 'answer';

  late String _uuidStr;
  late Db _db;
  late DbCollection _collection;
  late DbCollection _settingsCollection;
  late Map<String, dynamic> _metaObj;

  final Set<String> _knownTags = {};

  @override
  String newConversation(List<String> tags, String owner, String topic) {
    _uuidStr = const Uuid().v1();
    _metaObj = {_uuid: _uuidStr , _tags: tags, _owner: owner, _topic: topic};
    saveTags(tags.toSet());
    return _uuidStr;
  }

  Future<void> _saveToDb(Map<String, dynamic> payload) async {
    await _collection.insert(payload);
  }

  Future<void> saveTags(Set<String> tags) async{
    if(tags.isEmpty) return Future.value();

    var q = where.eq('$_meta.$_uuid',_uuidStr);
    var u = modify.set(_tags, tags);
    var r = await _collection.update(q, u);
    log('Updated $_uuidStr tags : $r');

    var diff = tags.difference(_knownTags);
    if(diff.isEmpty){
      log("All tags are known");
    }
    else{
      log("Saving new tags $diff");
      _knownTags.addAll(diff);
      var q = where.eq(_settingsName, _settingsApp);
      var app = await _settingsCollection.findOne(q);
      if(app != null){
        var u = modify.set(_tags, diff);
        await _settingsCollection.update(q, u);
      }
      else{
        await _settingsCollection.insert({_settingsName: _settingsApp, _tags: diff});
      }
    }
  }

  @override
  Future<void> answer(OpenAIChatCompletionModel msg) async{
    Map<String, dynamic> payload = {_meta: _metaObj};
    payload[_answer] = msg.toMap();
    payload[_fromAi] = true;
    _saveToDb(payload);
  }

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<bool> connect() async {
    _db = await Db.create(Env.mongoDbConnStr);
    await _db.open() ;
    _collection = _db.collection(_collectionName);
    _settingsCollection = _db.collection(_settingsCollectionName);
    return _db.isConnected;
  }

  @override
  Future<void> question(String msg) async{
    Map<String, dynamic> payload = {_meta: _metaObj};
    payload[_fromAi] = false;
    payload[_question] = msg;
    _saveToDb(payload);
  }
}