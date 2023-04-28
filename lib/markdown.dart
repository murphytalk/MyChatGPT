import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

String detectLang(String text) {
  return 'java';
}

String processMarkdown(String markdownText) {
  // Regular expression to match code blocks surrounded by triple backticks
  RegExp codeBlockPattern = RegExp(r'```([\s\S]*?)```', multiLine: true);

  return markdownText.replaceAllMapped(codeBlockPattern, (match) {
    String? codeBlockContent = match.group(1);
    String detectedLanguage = detectLang(codeBlockContent!);

    final s = '```$detectedLanguage\n$codeBlockContent```';
    log(s);
    return s;
  });
}
