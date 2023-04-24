import 'package:flutter/material.dart';
import 'package:dart_openai/openai.dart';
import 'package:my_chat_gpt/storage.dart';
import 'package:my_chat_gpt/utils.dart';
import 'env/env.dart';
import 'open_ai.dart';
import 'dart:developer' as dev;

void main() {
  OpenAI.apiKey = Env.openApiKey;
  runApp(const MyApp());
}

final IStorage storage = MongoDbStorage();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    try {
      return FutureBuilder(
          future: storage.connect(),
          builder: (ctx, AsyncSnapshot<bool> dbConnected) {
            Widget child;
            if (dbConnected.hasData) {
              dev.log("db connected: ${dbConnected.data}");
              child = MaterialApp(
                title: 'My AI Agent',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                ),
                home: const MyHomePage(title: 'My ChatGPT'),
              );
            } else {
              child = const AwaitWidget(caption: "Connecting ...");
            }
            return Center(child: child);
          });
    }
    catch(e){
      showErrorDialog(context, e.toString());
      return const Center();
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: const OpenAIChat(),
    );
  }
}
