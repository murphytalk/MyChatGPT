import 'package:flutter/material.dart';
import 'package:my_chat_gpt/main.dart';
import 'package:tuple/tuple.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Tuple2<String, String>> _history = [];
  static const _itemsPerPage = 20;
  int _loadedItemsCount = 0;
  bool _isLoadingMoreItems = false;

  Future<void> _loadItems() async {
    final result = await storage.getHistory(_itemsPerPage, _loadedItemsCount);

    setState(() {
      _history.addAll(result);
      _loadedItemsCount += result.length;
    });
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMoreItems) {
      return;
    }

    setState(() {
      _isLoadingMoreItems = true;
    });

    final result = await storage.getHistory(_itemsPerPage, _loadedItemsCount);

    setState(() {
      _history.addAll(result);
      _loadedItemsCount += result.length;
      _isLoadingMoreItems = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: ListView.builder(
        itemCount: _history.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index == _history.length) {
            _loadMoreItems();
            return SizedBox(
              height: 40,
              width: 40,
              child: Center(
                child: _isLoadingMoreItems
                    ? const CircularProgressIndicator()
                    : null,
              ),
            );
          }

          final item = _history[index];
          final uuid = item.item1;
          final topic = item.item2;

          return ListTile(
            title: Text(
              topic,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/conversation',
                arguments: uuid,
              );
            },
          );
        },
      ),
    );
  }
}
