import 'package:flutter/material.dart';
import 'dart:developer' as dev;

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
              child: Directionality(textDirection: TextDirection.ltr, child: Text(caption))))
    ]);
  }
}

void log(String msg){
  dev.log(msg, time:DateTime.now());
}

class ErrorAlertScreen extends StatelessWidget {
  final String errorMessage;

  const ErrorAlertScreen({Key? key, required this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 100,
            color: Colors.orangeAccent,
          ),
          SizedBox(height: 30),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}