import 'package:flutter/material.dart';

import 'main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void dispose() {
    storage.saveConfig();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Minimal number of messages in conversation',
              /*
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),*/
            ),
            const SizedBox(height: 16.0),
            Slider(
                value: AppState()
                    .config
                    .minMsgNumOfConversationShownInHistory
                    .toDouble(),
                min: 0.0,
                max: 5.0,
                divisions: 5,
                label: AppState()
                    .config
                    .minMsgNumOfConversationShownInHistory
                    .toString(),
                onChanged: (v) => setState(
                      () => AppState()
                          .config
                          .minMsgNumOfConversationShownInHistory = v.toInt(),
                    )),
          ],
        ),
      ),
    );
  }
}
