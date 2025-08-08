import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiVoiceAssistantPage extends StatefulWidget {
  const AiVoiceAssistantPage({super.key});

  @override
  State<AiVoiceAssistantPage> createState() => _AiVoiceAssistantPageState();
}

class _AiVoiceAssistantPageState extends State<AiVoiceAssistantPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: state.conversationHistory.length,
                  itemBuilder: (context, index) {
                    final message = state.conversationHistory[index];
                    final isUserMessage = message.startsWith('You: ');
                    return Align(
                      alignment: isUserMessage
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUserMessage
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message.replaceFirst(isUserMessage ? 'You: ' : 'AI: ', ''),
                          style: TextStyle(
                            color: isUserMessage ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type your command...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final command = _textController.text;
                    if (command.isNotEmpty) {
                      context
                          .read<AiVoiceAssistantBloc>()
                          .add(ProcessCommandEvent(command));
                      _textController.clear();
                    }
                  },
                ),
                BlocBuilder<AiVoiceAssistantBloc, AiVoiceAssistantState>(
                  builder: (context, state) {
                    if (state is AiVoiceAssistantListening) {
                      return IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () {
                          context
                              .read<AiVoiceAssistantBloc>()
                              .add(StopListeningEvent());
                        },
                      );
                    }
                    return IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: () {
                        context
                            .read<AiVoiceAssistantBloc>()
                            .add(StartListeningEvent());
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
