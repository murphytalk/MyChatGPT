import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_chat_gpt/main.dart';
import 'package:my_chat_gpt/utils.dart';

class OpenAIChat extends StatefulWidget {
  const OpenAIChat({super.key});

  @override
  OpenAIChatState createState() => OpenAIChatState();
}

@immutable
class _Message{
  final bool fromAI;
  final String content;
  const _Message({required this.fromAI, required this.content});
}


class OpenAIChatState extends State<OpenAIChat> {
  final TextEditingController _textController = TextEditingController();
  final List<_Message> _messages = [];
  String? _curConversationId;

  Future<String> _getOpenAiResponse(List<_Message> messages) async{
    final completions = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: messages.map( (m) =>
          OpenAIChatCompletionChoiceMessageModel(
            content: m.content,
          role: OpenAIChatMessageRole.user,
        )).toList(growable: false)
    );
    storage.answer(completions);
    return completions.choices[0].message.content;
  }

  void _sendMessage(BuildContext ctx,String message) async {
    setState(() {
      storage.question(message);
      _messages.add(_Message(fromAI: false, content: message));
    });
    try {
      final response = await _getOpenAiResponse(_messages);
      setState(() {
        _messages.add(_Message(fromAI: true, content: response));
      });
    }
    catch(e){
      showErrorDialog(ctx, e.toString());
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final isMarkdown = _messages[index].fromAI;
              final content = _messages[index].content;
              return isMarkdown
                  ? Markdown(
                data: content,
                shrinkWrap: true,
              )
                  : ListTile(
                title: Text(content),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    labelText: 'Ask a question',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  _curConversationId ??= storage.newConversation(["test"], "mu", _textController.text);
                  _sendMessage(context, _textController.text);
                  _textController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
