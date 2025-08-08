import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/voice_assistant_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiVoiceAssistantPage extends StatelessWidget {
  const AiVoiceAssistantPage({super.key});

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
                if (state is AiVoiceAssistantListening) {
                  return ListView(
                    children: [
                      ListTile(
                        title: Text(state.recognizedText),
                      ),
                    ],
                  );
                } else if (state is AiVoiceAssistantSuccess) {
                  return ListView(
                    children: [
                      ListTile(
                        title: Text(state.message),
                      ),
                    ],
                  );
                } else if (state is AiVoiceAssistantError) {
                  return ListView(
                    children: [
                      ListTile(
                        title: Text(state.message, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          const VoiceAssistantButton(),
        ],
      ),
    );
  }
}
