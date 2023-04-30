import 'package:flutter/material.dart';
import 'package:my_chat_gpt/main.dart';
import 'package:my_chat_gpt/storage.dart';
import 'package:my_chat_gpt/utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ConversationInfo> _documents = [];
  static const int _limit = 20;
  bool _isLoading = false;
  int _skip = 0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _getDocuments();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getDocuments();
      }
    });
  }

  Future<void> _getDocuments() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    final documents = await storage.getHistory(AppState().user,
        AppState().config.minMsgNumOfConversationShownInHistory, _limit, _skip);
    setState(() {
      _isLoading = false;
      _documents.addAll(documents);
      _skip += documents.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: _documents.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _documents.length && _isLoading) {
            return const AwaitWidget(caption: 'Loading');
          }
          final document = _documents[index];
          return ListTile(
            title: Text(document.topic,
                overflow: TextOverflow.ellipsis,
                style: txtStyle(document.isChinese, FontWeight.normal)),
            selected: _selected == index,
            onTap: () {
              setState(() {
                _selected = index;
              });
              Navigator.pushNamed(context, AppState.routeHome,
                  arguments: document);
            },
          );
        },
      ),
    );
  }
}
