import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/voice_assistant_button.dart';
import 'package:flutter/material.dart';

class AiVoiceAssistantPage extends StatelessWidget {
  const AiVoiceAssistantPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Voice Assistant'),
      ),
      body: const Center(
        child: VoiceAssistantButton(),
      ),
    );
  }
}
