import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/goal_card.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/add_goal_section.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Add this to trigger fetching goals when the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialsBloc>().add(FetchGoals());
    });

    return BlocConsumer<FinancialsBloc, FinancialsState>(
      listener: (context, state) {
        if (state is FinancialsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text(state.message))),
          );
        } else if (state is FinancialsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text(state.message))),
          );
        }
      },
      builder: (context, state) {
        final goals = state.goals.whereType<GoalModelBase>().toList();
        final isLoading = goals.isEmpty && state.goals.isEmpty;
        
        return Scaffold(
          appBar: AppBar(
            title: Text('financialGoals'.tr()),
            centerTitle: true,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AddGoalSection(),
                    const SizedBox(height: 24),
                    Text(
                      'trackFinancialGoalsThisYear'.tr(),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (isLoading)
                      const ShimmerList(itemCount: 3)
                    else
                      ...goals.map((goal) => GoalCard(goal: goal)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

