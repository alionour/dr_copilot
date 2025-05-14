import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

class GoalCard extends StatelessWidget {
  final GoalModelBase goal;
  const GoalCard({required this.goal, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              goal.title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            if (goal.description?.isNotEmpty == true)
              Text(
                goal.description!,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),
            const SizedBox(height: 18),
            Builder(
              builder: (context) {
                final bloc = BlocProvider.of<FinancialsBloc>(context);
                final progress = bloc.calculateGoalProgress(goal);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Color(goal.color).withValues(alpha: (0.15 * 255).toDouble()),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(goal.color)),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'progressLabelWithPercent'.tr(args: [(progress * 100).toStringAsFixed(0)]),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(goal.color),
                            fontSize: 14),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
