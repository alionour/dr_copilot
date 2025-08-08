import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:flutter/material.dart';

class ConfirmationCard extends StatelessWidget {
  final Command command;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationCard({
    super.key,
    required this.command,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Command'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intent: ${command.intent}'),
          const SizedBox(height: 16),
          const Text('Entities:'),
          ...command.entities.entries.map(
            (entry) => Text('- ${entry.key}: ${entry.value}'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onConfirm,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
