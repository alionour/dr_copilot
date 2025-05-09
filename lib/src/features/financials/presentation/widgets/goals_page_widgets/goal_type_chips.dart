import 'package:flutter/material.dart';

class GoalTypeChips extends StatelessWidget {
  final List<Map<String, String>> goalTypes;
  final String selectedGoalType;
  final ValueChanged<String> onChanged;
  const GoalTypeChips({
    super.key,
    required this.goalTypes,
    required this.selectedGoalType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: goalTypes
          .map((type) => ChoiceChip(
                label: Text(type['label']!),
                selected: selectedGoalType == type['key'],
                onSelected: (_) => onChanged(type['key']!),
                selectedColor: Colors.teal,
                labelStyle: TextStyle(
                  color: selectedGoalType == type['key']
                      ? Colors.white
                      : Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.teal[50],
              ))
          .toList(),
    );
  }
}
