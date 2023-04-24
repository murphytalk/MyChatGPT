import 'package:flutter/material.dart';

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
