import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/models/assistant_action_model.dart';

class DynamicActionUI extends StatelessWidget {
  final AssistantActionModel? currentAction;
  final String? aiResponse;
  final Function(Map<String, dynamic>) onActionSubmit;
  final Function(String) onUserResponse;
  final VoidCallback onClearAction;

  const DynamicActionUI({
    super.key,
    this.currentAction,
    this.aiResponse,
    required this.onActionSubmit,
    required this.onUserResponse,
    required this.onClearAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
