import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/models/copilot_model.dart';

class CopilotCard extends StatelessWidget {
  final CopilotModel copilot;

  const CopilotCard({super.key, required this.copilot});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(copilot.name),
        subtitle: Text(copilot.role),
      ),
    );
  }
}

