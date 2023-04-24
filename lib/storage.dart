import 'package:dart_openai/openai.dart';
import 'package:flutter/cupertino.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:my_chat_gpt/env/env.dart';


abstract class IStorage{
  Future<bool> connect();
  Future<void> close();
  String newConversation(List<String> tags, String owner, String topic);
  Future<void> question(String msg);
  Future<void> answer(OpenAIChatCompletionModel msg);
}

class MongoDbStorage implements IStorage{
  static const _collectionName = 'MyChatGPT';
  static const _tags = 'tags';
  static const _owner = 'owner';
  static const _topic = 'topic';
  static const _fromAi = 'from_ai';
  static const _meta = 'meta';
  static const _uuid = 'uuid';
  static const _question = 'question';

  late String _uuidStr;
  late Db _db;
  late DbCollection _collection;
  late Map<String, dynamic> _metaObj;

  @override
  String newConversation(List<String> tags, String owner, String topic) {
    _uuidStr = const Uuid().v1();
    _metaObj = {_uuid: _uuidStr , _tags: tags, _owner: owner, _topic: topic};
    return _uuidStr;
  }

  @override
  Future<void> answer(OpenAIChatCompletionModel msg) async{
    var payload = msg.toMap();
    payload[_meta] = _metaObj;
    payload[_fromAi] = true;
    await _collection.insert(payload);
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
    return _db.isConnected;
  }

  @override
  Future<void> question(String msg) async{
    Map<String, dynamic> payload = {_meta: _metaObj};
    payload[_fromAi] = false;
    payload[_question] = msg;
    await _collection.insert(payload);
  }
}