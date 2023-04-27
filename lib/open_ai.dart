import 'package:dart_openai/openai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_chat_gpt/main.dart';
import 'package:my_chat_gpt/storage.dart';
import 'package:my_chat_gpt/utils.dart';

class OpenAIChat extends StatefulWidget {
  const OpenAIChat({super.key});

  @override
  OpenAIChatState createState() => OpenAIChatState();
}


class OpenAIChatState extends State<OpenAIChat> with RouteAware{
  final TextEditingController _textController = TextEditingController();
  List<Message> _messages = [];
  String? _curConversationId;
  bool _thinking = false;
  bool _loadConversation = false;
  bool _observerRegistered = false;

  static const _prompt = 'AI tutor,answer my question concisely without elaboration';

  Future<String> _getOpenAiResponse(List<Message> messages) async{
    final first = OpenAIChatCompletionChoiceMessageModel(
      content: _prompt,
      role: OpenAIChatMessageRole.user,
    );
    final completions = await OpenAI.instance.chat.create(
        model: "gpt-3.5-turbo",
        messages: [first, ... messages.map( (m) =>
          OpenAIChatCompletionChoiceMessageModel(
            content: m.content,
          role: OpenAIChatMessageRole.user,
        )).toList(growable: false)]
    );
    storage.answer(completions);
    return completions.choices[0].message.content;
  }

  void _sendMessage(BuildContext ctx,String message) async {
    setState(() {
      _messages.add(Message(fromAI: false, content: message));
    });

    storage.question(message);

    setState(() {
       _thinking = true;
    });

    try {
      final response = await _getOpenAiResponse(_messages);
      setState(() {
        _thinking = false;
        _messages.add(Message(fromAI: true, content: response));
      });
    }
    catch(e){
      showErrorDialog(ctx, e.toString());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(!_observerRegistered) {
      log('route observer registered');
      _observerRegistered = true;
      routeObserver.subscribe(this, ModalRoute.of(context)!);
    }
  }

  @override
  void dispose() {
    log('route observer unregistered');
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if(AppState().conversationToLoad.isNotEmpty){
      setState(() => _loadConversation = true);
    }
  }

  Widget _buildNormalUi(BuildContext context) {
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
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  _textController.clear();
                  storage.newConversation([], "mu", _textController.text)
                      .then((v) {
                    _curConversationId = v;
                    _textController.clear();
                  })
                      .catchError((e) {
                    showErrorDialog(context, e.toString());
                  });
                },
              ),
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
                  var q = _textController.text.trim();
                  if (q.isNotEmpty) {
                    if (_curConversationId == null) {
                      storage.newConversation(
                          [], AppState().user.name, q)
                          .then((value) {
                        _curConversationId = value;
                        _textController.clear();
                        _sendMessage(context, q);
                      })
                          .catchError((e) {
                        showErrorDialog(context, e.toString());
                      });
                    }
                    else {
                      storage.question(q).then((_) {
                        _sendMessage(context, q);
                        _textController.clear();
                      })
                          .catchError((e) {
                        showErrorDialog(context, e.toString());
                      });
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );}

    @override
    Widget build(BuildContext context) {
      if(_thinking) return const Center(child: AwaitWidget(caption: "Thinking ..."));


      if(_loadConversation && AppState().conversationToLoad.isNotEmpty){
        return FutureBuilder(
            future: storage.getConversation(AppState().conversationToLoad.uuid),
            builder: (ctx, conversation){
              AppState().conversationToLoad = ConversationInfo.empty();
              _loadConversation = false;
              if(conversation.hasData){
                //setState(() => );
                _messages = conversation.data?.messages ?? [];
                return _buildNormalUi(context);
              }
              else if(conversation.hasError){
                if(conversation.error !=null){
                  return AlertDialog(
                    title: const Text('Could not load conversion'),
                    content: Text(conversation.error.toString()),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () {
                          //trigger rebuild
                          setState((){});
                        },
                      ),
                    ],
                  );
                }
                return _buildNormalUi(context);
              }
              else {
                return Center(child: AwaitWidget(caption: "Loading ${AppState().conversationToLoad.topic}",));
              }
            });
      }
      else {
        return _buildNormalUi(context);
      }
    }
}
