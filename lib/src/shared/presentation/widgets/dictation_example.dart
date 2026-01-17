import 'package:flutter/material.dart';
import 'package:dr_copilot/src/shared/presentation/widgets/dictation_button.dart';

/// Example demonstrating how to use the DictationButton widget
/// in a text field or rich text editor.
class DictationExample extends StatefulWidget {
  const DictationExample({super.key});

  @override
  State<DictationExample> createState() => _DictationExampleState();
}

class _DictationExampleState extends State<DictationExample> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextTranscribed(String transcribedText) {
    // Append transcribed text to the current text
    // You can customize this behavior as needed
    final currentText = _textController.text;
    final newText =
        currentText.isEmpty ? transcribedText : '$currentText $transcribedText';

    _textController.text = newText;

    // Move cursor to end
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: newText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dictation Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: InputDecoration(
                labelText: 'Clinical Notes',
                border: const OutlineInputBorder(),
                // Add dictation button as suffix
                suffixIcon: DictationButton(
                  onTextTranscribed: _onTextTranscribed,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap the microphone icon to start dictation. '
              'Speak your notes and they will appear in real-time. '
              'Tap again to stop and finalize the transcription.',
            ),
          ],
        ),
      ),
    );
  }
}
