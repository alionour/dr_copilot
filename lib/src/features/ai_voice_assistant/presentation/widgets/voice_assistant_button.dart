import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VoiceAssistantButton extends StatelessWidget {
  const VoiceAssistantButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      listener: (context, state) {
        if (state is AiVoiceAssistantError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AiVoiceAssistantListening) {
          return FloatingActionButton(
            onPressed: () {
              context
                  .read<AiVoiceAssistantBloc>()
                  .add(ProcessCommandEvent(state.recognizedText));
            },
            child: const Icon(Icons.stop),
          );
        }

        if (state is AiVoiceAssistantProcessing) {
          return const FloatingActionButton(
            onPressed: null,
            child: CircularProgressIndicator(),
          );
        }

        return FloatingActionButton(
          onPressed: () {
            context.read<AiVoiceAssistantBloc>().add(StartListeningEvent());
          },
          child: const Icon(Icons.mic),
        );
      },
    );
  }
}

// TODO: Implement a full conversation UI with history.
