import 'package:flutter/material.dart';
import 'package:dart_openai/openai.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_chat_gpt/edit.dart';
import 'package:my_chat_gpt/history.dart';
import 'package:my_chat_gpt/storage.dart';
import 'env/env.dart';
import 'open_ai.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  OpenAI.apiKey = Env.openApiKey;
  runApp(const MyApp());
}

final IStorage storage = MongoDbStorage();

class AppState {
  static final AppState _singleton = AppState._internal();

  User user = User.defaultUser();
  bool multipleUser = false;
  Config config = Config.defaultCfg();

  factory AppState() {
    return _singleton;
  }

  AppState._internal();

  static const routeHome = '/h';
  static const routeHistory = '/hist';
  static const routeSettings = '/s';
}

class _SplashScreen extends StatefulWidget {
  final Widget? Function(BuildContext, List<User>) homeScreenBuilder;
  final Widget Function(BuildContext, String) errScreenBuilder;

  const _SplashScreen({
    required this.homeScreenBuilder,
    required this.errScreenBuilder,
  });

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap().then((users) {
      final nextScreen = widget.homeScreenBuilder(context, users);
      if (nextScreen != null) {
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (ctx) => nextScreen));
      } else {
        Navigator.pushReplacementNamed(context, AppState.routeHome);
      }
    }).catchError((e) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (ctx) => widget.errScreenBuilder(ctx, e.toString())));
    });
  }

  Future<List<User>> _bootstrap() async {
    var connected = await storage.connect();
    if (!connected) return Future.error("Failed to connect to db");
    AppState().config = await storage.getConfig();
    return storage.getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.green],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String _title = 'My ChatGPT';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'My AI Agent',
        debugShowCheckedModeBanner: false,
        home: _SplashScreen(
            homeScreenBuilder: (_, users) {
              if (users.length > 1) {
                AppState().multipleUser = true;
                return _AvatarScreen(users: users);
              } else {
                AppState().user = users[0];
                return null;
              }
            },
            errScreenBuilder: (_, err) => Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Error: $err'),
                      ),
                    ]))),
        routes: {
          AppState.routeHome: (c) => const MyHomePage(title: _title),
          AppState.routeHistory: (c) => const HistoryScreen(),
          AppState.routeSettings: (c) => const SettingsScreen(),
        },
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ));
  }
}

class _AvatarScreen extends StatefulWidget {
  final List<User> users;
  const _AvatarScreen({required this.users});

  @override
  _AvatarScreenState createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<_AvatarScreen> {
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
          return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    widget.users[index].name[0],
                    style: const TextStyle(fontSize: 26.0),
                  ),
                ),
                title: Text(
                  widget.users[index].fullName,
                  style: const TextStyle(fontSize: 32.0),
                ),
                selected: _selected == index,
                onTap: () {
                  setState(() {
                    _selected = index;
                  });
                  AppState().user = widget.users[index];
                  Navigator.pushReplacementNamed(context, AppState.routeHome);
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

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = AppState().multipleUser
        ? [
            IconButton(
              onPressed: () => storage.getUsers().then((users) =>
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (ctx) => _AvatarScreen(users: users)))),
              icon: const Icon(Icons.group),
              tooltip: 'Switch User',
            )
          ]
        : [];
    actions.addAll(
      [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppState.routeHistory),
          icon: const Icon(Icons.history),
          tooltip: 'History',
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppState.routeSettings),
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        )
      ],
    );
    return Scaffold(
      appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back))
              : null,
          title: Text(widget.title),
          actions: actions),
      body: const OpenAIChat(),
    );
  }
}
