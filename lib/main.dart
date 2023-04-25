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

  Future<List<User>> _bootstrap() async{
    var connected = await storage.connect();
    if(!connected) throw Exception("Failed to connect to db");
    return storage.getUsers();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
      return FutureBuilder(
          future: _bootstrap(),
          builder: (ctx, AsyncSnapshot<List<User>> dbConnected) {
            Widget child;
            if (dbConnected.hasData) {
              final  users = dbConnected.data ?? [];
              child = MaterialApp(
                title: 'My AI Agent',
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                ),
                home: MyHomePage(title: 'My ChatGPT', users: users),
              );
            } else if (dbConnected.hasError){
              child = Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('Error: ${dbConnected.error}'),
                  ),
                ]));
            }
            else {
              child = const AwaitWidget(caption: "Connecting ...");
            }
            return Center(child: child);
          });
    }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.users});
  final String title;
  final List<User> users;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      drawer: Drawer(
       child: ListView(
         padding: EdgeInsets.zero,
         children: const <Widget>[
           DrawerHeader(
             decoration: BoxDecoration(
               color: Colors.blue,
             ),
             child: Text(
               'Drawer Header',
               style: TextStyle(
                 color: Colors.white,
                 fontSize: 24,
               ),
             ),
           ),
           ListTile(
             leading: Icon(Icons.message),
             title: Text('Messages'),
           ),
         ],
       )
      ),
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: const OpenAIChat(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    storage.close();
  }
}
