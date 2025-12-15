import 'package:dr_copilot/src/features/copilot_chat/domain/models/copilot_model.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/copilot_card.dart';
import 'package:flutter/material.dart';

class CopilotList extends StatelessWidget {
  final List<CopilotModel> copilots;

  const CopilotList({super.key, required this.copilots});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: copilots.length,
      itemBuilder: (context, index) {
        return CopilotCard(copilot: copilots[index]);
      },
    );
  }
}

