import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:flutter/material.dart';

class ConfirmationCard extends StatefulWidget {
  final Command command;
  final Function(Command) onConfirm;
  final VoidCallback onCancel;

  const ConfirmationCard({
    super.key,
    required this.command,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends State<ConfirmationCard> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var entry in widget.command.entities.entries)
        entry.key: TextEditingController(text: entry.value.toString()),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Command'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Intent: ${widget.command.intent}'),
          const SizedBox(height: 16),
          const Text('Entities:'),
          ...widget.command.entities.entries.map(
            (entry) => TextField(
              controller: _controllers[entry.key],
              decoration: InputDecoration(labelText: entry.key),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedEntities = {
              for (var entry in _controllers.entries)
                entry.key: entry.value.text,
            };
            final updatedCommand = Command(
              intent: widget.command.intent,
              entities: updatedEntities,
            );
            widget.onConfirm(updatedCommand);
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
