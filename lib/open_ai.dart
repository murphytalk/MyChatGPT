import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_chat_gpt/main.dart';
import 'package:my_chat_gpt/storage.dart';
import 'package:my_chat_gpt/utils.dart';

class OpenAIChat extends StatefulWidget {
  const OpenAIChat({super.key});

  @override
  OpenAIChatState createState() => OpenAIChatState();
}

class OpenAIChatState extends State<OpenAIChat> {
  final TextEditingController _textController = TextEditingController();
  List<Message> _messages = [];
  String? _curConversationId;
  bool _thinking = false;
  bool _canAskQuestion = true;
  bool _copyMode = false;

  static const _prompt =
      'AI tutor,answer my question concisely without elaboration';

  Future<String> _getOpenAiResponse(List<Message> messages) async {
    final first = OpenAIChatCompletionChoiceMessageModel(
      content: _prompt,
      role: OpenAIChatMessageRole.user,
    );
    final completions =
        await OpenAI.instance.chat.create(model: "gpt-3.5-turbo", messages: [
      first,
      ...messages
          .map((m) => OpenAIChatCompletionChoiceMessageModel(
                content: m.content,
                role: OpenAIChatMessageRole.user,
              ))
          .toList(growable: false)
    ]);
    storage.answer(completions);
    return completions.answer;
  }

  Future<void> _sendMessage(BuildContext ctx, String message) async {
    setState(() {
      _messages.add(Message(
          fromAI: false,
          content: message,
          language: detectLanguage(string: message)));
    });

    storage.question(message);

    setState(() {
      _thinking = true;
    });

    try {
      final response = await _getOpenAiResponse(_messages);
      setState(() {
        _thinking = false;
        _messages.add(Message(
            fromAI: true,
            content: response,
            language: detectLanguage(string: message)));
      });
    } catch (e) {
      showErrorDialog(ctx, e.toString());
    }
  }

  void _submitQuestion() {
    var q = _textController.text.trim();
    if (q.isNotEmpty) {
      if (_curConversationId == null) {
        setState(() => _canAskQuestion = false);
        final newLinePos = q.indexOf('\n');
        final topic = newLinePos > 0 ? q.substring(0, newLinePos) : q;
        storage.newConversation([], AppState().user.name, topic).then((value) {
          _curConversationId = value;
          _textController.clear();
          _sendMessage(context, q)
              .whenComplete(() => setState(() => _canAskQuestion = true));
        }).catchError((e) {
          showErrorDialog(context, e.toString());
        });
      } else {
        _sendMessage(context, q)
            .whenComplete(() => setState(() => _canAskQuestion = true));
        _textController.clear();
      }
    }
  }

  bool _handleKeyPressed(RawKeyEvent ev) {
    if (ev is RawKeyDownEvent &&
        ev.logicalKey == LogicalKeyboardKey.enter &&
        ev.isControlPressed) {
      _submitQuestion();
      return false;
    }
    return true;
  }

  Widget _buildNormalUi(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isMarkdown = msg.fromAI;
              final content = msg.content;
              return _copyMode
                  ? SelectableText(content,
                      style: TextStyle(
                          fontWeight:
                              isMarkdown ? FontWeight.normal : FontWeight.bold))
                  : (isMarkdown
                      ? Markdown(
                          data: content,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet(),
                        )
                      : ListTile(
                          title: Text(content,
                              style: txtStyle(msg.isChinese, FontWeight.w600)),
                        ));
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _copyMode = !_copyMode),
                icon: Icon(
                  Icons.content_copy,
                  color: _copyMode ? Colors.blue : Colors.black,
                ),
                tooltip: 'Copy mode',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  _textController.clear();
                  setState(() {
                    _curConversationId = null;
                    _messages = [];
                  });
                },
                tooltip: 'New conversation',
              ),
              Expanded(
                  child: RawKeyboardListener(
                onKey: _handleKeyPressed,
                focusNode: FocusNode(),
                child: TextField(
                  enabled: _canAskQuestion,
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  minLines: 1,
                  decoration: const InputDecoration(
                    labelText: 'Ask a question, Ctrl-Enter to submit',
                  ),
                ),
              )),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _submitQuestion(),
                tooltip: 'Submit',
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_thinking) {
      return const Center(child: AwaitWidget(caption: 'Thinking'));
    }

    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg != null && (arg as ConversationInfo).isNotEmpty) {
      _curConversationId = arg.uuid;
      return FutureBuilder(
          future: storage.getConversation(arg.uuid),
          builder: (ctx, conversation) {
            if (conversation.hasData) {
              storage.resumeConversation(_curConversationId!);
              _messages = conversation.data?.messages ?? [];
              return _buildNormalUi(context);
            } else if (conversation.hasError) {
              _curConversationId = null;
              if (conversation.error != null) {
                return AlertDialog(
                  title: const Text('Could not load conversation'),
                  content: Text(conversation.error.toString()),
                  actions: <Widget>[
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () {
                        //trigger rebuild
                        setState(() {});
                      },
                    ),
                  ],
                );
              }
              return _buildNormalUi(context);
            } else {
              return const Center(child: AwaitWidget(caption: "Loading ..."));
            }
          });
    } else {
      return _buildNormalUi(context);
    }
  }
}
