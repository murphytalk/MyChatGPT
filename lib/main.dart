import 'package:flutter/material.dart';
import 'package:dart_openai/openai.dart';
import 'package:my_chat_gpt/history.dart';
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

class AppState {
  static final AppState _singleton = AppState._internal();

  factory AppState() { return _singleton; }
  AppState._internal();
}

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
                initialRoute: '/',
                routes: {
                  '/': (c) => AvatarScreen(users: users),
                  '/home': (c) => const MyHomePage(title: 'My ChatGPT'),
                  '/history': (c) => const HistoryScreen(),
                },
                theme: ThemeData(
                  primarySwatch: Colors.blue,
                ),
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


class AvatarScreen extends StatefulWidget {
  final List<User> users;
  const AvatarScreen({super.key, required this.users});

  @override
  _AvatarScreenState createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> {
  int _selected = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Are You?'),
      ),
      body: ListView.builder(
        itemCount: widget.users.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: ListTile(
            leading: CircleAvatar(
              child: Text(widget.users[index].name[0], style: const TextStyle(fontSize: 26.0),),
            ),
            title: Text(widget.users[index].fullName, style: const TextStyle(fontSize: 32.0),),
            selected: _selected == index,
            onTap: () {
              setState(() {
                _selected = index;
              });
              Navigator.pushReplacementNamed(context, '/home', arguments: {'user': widget.users[index]});
            },
          ));
        },
      ),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{
  late User _user;
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

// Extract the arguments from the ModalRoute settings.
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if(args == null){
      showErrorDialog(context, "Something went wrong, I don't know who you are!");
    }
    else{
      final a = args as Map<String, dynamic>;
      if(a.containsKey('user')) {
        _user = a['user'] as User;
      }
      if(a.containsKey('uuid')){
        final String uuid = a['uuid'];
        dev.log('Loading conversation $uuid');
      }
    }
    return Scaffold(
      drawer: Drawer(
       child: ListView(
         padding: EdgeInsets.zero,
         children: <Widget>[
           DrawerHeader(
             decoration: const BoxDecoration(
               color: Colors.blue,
             ),
             child: CircleAvatar(
               child: Text(_user.fullName[0], style: const TextStyle(fontSize: 32.0)),
             ),
           ),
           ListTile(
             leading: const Icon(Icons.history),
             title: const Text('History'),
             onTap: () => Navigator.pushNamed(context, '/history')
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
