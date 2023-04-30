import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:developer' as dev;

import 'package:google_fonts/google_fonts.dart';

void showErrorDialog(BuildContext context, String error) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('API Error'),
        content: Text(error),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class AwaitWidget extends StatelessWidget {
  final String caption;
  const AwaitWidget({super.key, required this.caption});
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(),
      ),
      DefaultTextStyle(
          style: Theme.of(context).textTheme.displayMedium!,
          textAlign: TextAlign.center,
          child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Directionality(
                  textDirection: TextDirection.ltr, child: Text(caption))))
    ]);
  }
}

void log(String msg) {
  dev.log(msg, time: DateTime.now());
}

String detectLanguage({required String string}) {
  String languageCodes = 'en';

  final RegExp chinese = RegExp(r'[\u4E00-\u9FFF]+');
  final RegExp japanese = RegExp(r'[\u3040-\u30FF]+');

  if (chinese.hasMatch(string)) languageCodes = 'zh';
  if (japanese.hasMatch(string)) languageCodes = 'ja';

  return languageCodes;
}

// This google font renders horribly for Chinese on windows, we use the Windows Chinese font
TextStyle txtStyle(bool isChinese) {
  return isChinese && Platform.isWindows
      ? const TextStyle(
          fontFamily: 'Microsoft YaHei', fontWeight: FontWeight.w600)
      : GoogleFonts.titilliumWeb(
          textStyle: const TextStyle(fontWeight: FontWeight.w600));
}

class ErrorAlertScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorAlertScreen({Key? key, required this.errorMessage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 100,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 30),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
