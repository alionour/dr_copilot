import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';

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
            SnackBar(content: Text(state.message)),
          );
        } else if (state is FinancialsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('financialGoals'.tr()),
            centerTitle: true,
            backgroundColor: Colors.green[200],
            elevation: 0,
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AddGoalSection(),
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
                    ...state.goals
                        .whereType<GoalModelBase>()
                        .map((goal) => _GoalCard(goal: goal)),
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

class _GoalCard extends StatelessWidget {
  final GoalModelBase goal;
  const _GoalCard({required this.goal});

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
                      backgroundColor: Color(goal.color).withOpacity(0.15),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(goal.color)),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'progressLabelWithPercent'
                            .tr(args: [(progress * 100).toStringAsFixed(0)]),
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

class _AddGoalSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            const Icon(Icons.add_task, color: Colors.teal, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'addFinancialGoal'.tr(),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  builder: (context) {
                    final formKey = GlobalKey<FormState>();
                    String title = '';
                    String? description;
                    String goalType = 'sessions_year';
                    Color color = Colors.teal;
                    // double progress = 0;
                    final List<Map<String, String>> goalTypes = [
                      {
                        'key': 'sessions_year',
                        'label': 'goalTypeSessionsYear'.tr()
                      },
                      {
                        'key': 'sessions_month',
                        'label': 'goalTypeSessionsMonth'.tr()
                      },
                      {
                        'key': 'decrease_expenses',
                        'label': 'goalTypeDecreaseExpenses'.tr()
                      },
                      {
                        'key': 'increase_revenue',
                        'label': 'goalTypeIncreaseRevenue'.tr()
                      },
                      {
                        'key': 'increase_profit',
                        'label': 'goalTypeIncreaseProfit'.tr()
                      },
                      {'key': 'custom', 'label': 'goalTypeCustom'.tr()},
                    ];
                    String customMetricName = '';
                    String customTargetValue = '';
                    String countTargetValue = '';
                    String amountTargetValue = '';
                    return StatefulBuilder(
                      builder: (context, setState) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          left: 24,
                          right: 24,
                          top: 24,
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('addNewGoal'.tr(),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal)),
                              const SizedBox(height: 18),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: goalTypes
                                    .map((type) => ChoiceChip(
                                          label: Text(type['label']!),
                                          selected: goalType == type['key'],
                                          onSelected: (_) => setState(
                                              () => goalType = type['key']!),
                                          selectedColor: Colors.teal,
                                          labelStyle: TextStyle(
                                            color: goalType == type['key']
                                                ? Colors.white
                                                : Colors.teal,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          backgroundColor: Colors.teal[50],
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'goalTitle'.tr(),
                                    border: const OutlineInputBorder()),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'required'.tr()
                                    : null,
                                onSaved: (v) => title = v ?? '',
                              ),
                              const SizedBox(height: 12),

                              if (goalType == 'custom') ...[
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'customMetricName'.tr(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'required'.tr()
                                      : null,
                                  onSaved: (v) => customMetricName = v ?? '',
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'customTargetValue'.tr(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^[0-9]+([.][0-9]{0,2})?')),
                                    LengthLimitingTextInputFormatter(
                                        11), // max 11 digits (up to 99,999,999,999)
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'required'.tr();
                                    }
                                    final n = num.tryParse(v);
                                    if (n == null) {
                                      return 'enterValidNumber'.tr();
                                    }
                                    if (n <= 0) {
                                      return 'mustBeGreaterThanZero'.tr();
                                    }
                                    if (n > 10000) {
                                      return 'valueTooLarge'.tr();
                                    }
                                    return null;
                                  },
                                  onSaved: (v) => customTargetValue = v ?? '',
                                ),
                                const SizedBox(height: 12),
                              ] else if (goalType == 'sessions_year' ||
                                  goalType == 'sessions_month') ...[
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'targetCount'.tr(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                        9), // max 9 digits (up to 999,999,999)
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'required'.tr();
                                    }
                                    final n = int.tryParse(v);
                                    if (n == null) {
                                      return 'enterValidInteger'.tr();
                                    }
                                    if (n <= 0) {
                                      return 'mustBeGreaterThanZero'.tr();
                                    }
                                    if (n > 100000000) {
                                      return 'valueTooLarge'.tr();
                                    }
                                    return null;
                                  },
                                  onSaved: (v) => countTargetValue = v ?? '',
                                ),
                                const SizedBox(height: 12),
                              ] else if (goalType == 'decrease_expenses' ||
                                  goalType == 'increase_revenue' ||
                                  goalType == 'increase_profit') ...[
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'targetAmount'.tr(),
                                    border: const OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^[0-9]+([.][0-9]{0,2})?')),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'required'.tr();
                                    }
                                    final n = double.tryParse(v);
                                    if (n == null) {
                                      return 'enterValidNumber'.tr();
                                    }
                                    if (n <= 0) {
                                      return 'mustBeGreaterThanZero'.tr();
                                    }
                                    if (n > 100000000) {
                                      return 'valueTooLarge'.tr();
                                    }
                                    return null;
                                  },
                                  onSaved: (v) => amountTargetValue = v ?? '',
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'goalDescription'.tr(),
                                    border: const OutlineInputBorder()),
                                validator: (v) =>
                                    null, // Description is optional
                                onSaved: (v) => description = v,
                              ),
                              const SizedBox(height: 12),
                              // StatefulBuilder(
                              //   builder: (context, setSliderState) {
                              //     return Column(
                              //       crossAxisAlignment:
                              //           CrossAxisAlignment.start,
                              //       children: [
                              //         Row(
                              //           children: [
                              //             Text('progressLabel'.tr(),
                              //                 style: const TextStyle(
                              //                     fontWeight: FontWeight.bold)),
                              //             const SizedBox(width: 8),
                              //             Text(
                              //                 'progressLabelWithPercent'.tr(
                              //                     args: [
                              //                       progress.toStringAsFixed(0)
                              //                     ]),
                              //                 style: const TextStyle(
                              //                     color: Colors.teal,
                              //                     fontWeight: FontWeight.bold)),
                              //           ],
                              //         ),
                              //         Slider(
                              //           value: progress,
                              //           min: 0,
                              //           max: 100,
                              //           divisions: 100,
                              //           label: 'progressLabelWithPercent'.tr(
                              //               args: [
                              //                 progress.toStringAsFixed(0)
                              //               ]),
                              //           onChanged: (v) {
                              //             setSliderState(() => progress = v);
                              //           },
                              //           activeColor: Colors.teal,
                              //           inactiveColor: Colors.teal[100],
                              //         ),
                              //       ],
                              //     );
                              //   },
                              // ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<Color>(
                                value: color,
                                decoration: InputDecoration(
                                    labelText: 'goalColor'.tr(),
                                    border: const OutlineInputBorder()),
                                items: [
                                  DropdownMenuItem(
                                    value: Colors.teal,
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                            backgroundColor: Colors.teal,
                                            radius: 8),
                                        const SizedBox(width: 8),
                                        Text('colorTeal'.tr()),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: Colors.green,
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                            backgroundColor: Colors.green,
                                            radius: 8),
                                        const SizedBox(width: 8),
                                        Text('colorGreen'.tr()),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: Colors.redAccent,
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                            backgroundColor: Colors.redAccent,
                                            radius: 8),
                                        const SizedBox(width: 8),
                                        Text('colorRed'.tr()),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: Colors.blue,
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                            backgroundColor: Colors.blue,
                                            radius: 8),
                                        const SizedBox(width: 8),
                                        Text('colorBlue'.tr()),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: Colors.orange,
                                    child: Row(
                                      children: [
                                        const CircleAvatar(
                                            backgroundColor: Colors.orange,
                                            radius: 8),
                                        const SizedBox(width: 8),
                                        Text('colorOrange'.tr()),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (c) => color = c ?? Colors.teal,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState!.validate()) {
                                    formKey.currentState!.save();
                                    final GoalType type =
                                        goalTypeFromString(goalType);
                                    GoalModelBase goal;
                                    if (type == GoalType.custom) {
                                      goal = CustomGoalModel(
                                        id: '',
                                        title: title,
                                        description: (description == null ||
                                                description!.trim().isEmpty)
                                            ? null
                                            : description!.trim(),
                                        goalType: type,
                                        metricName: customMetricName,
                                        targetValue: double.tryParse(
                                                customTargetValue) ??
                                            1.0,
                                        color: color.value,
                                        createdAt: Timestamp.fromDate(
                                            DateTime.now().toUtc()),
                                      );
                                    } else if (type.isCountBased) {
                                      goal = CountGoalModel(
                                        id: '',
                                        title: title,
                                        description: (description == null ||
                                                description!.trim().isEmpty)
                                            ? null
                                            : description!.trim(),
                                        goalType: type,
                                        targetCount:
                                            int.tryParse(countTargetValue) ?? 1,
                                        color: color.value,
                                        createdAt: Timestamp.fromDate(
                                            DateTime.now().toUtc()),
                                      );
                                    } else {
                                      goal = AmountGoalModel(
                                        id: '',
                                        title: title,
                                        description: (description == null ||
                                                description!.trim().isEmpty)
                                            ? null
                                            : description!.trim(),
                                        goalType: type,
                                        targetAmount: double.tryParse(
                                                amountTargetValue) ??
                                            1.0,
                                        color: color.value,
                                        createdAt: Timestamp.fromDate(
                                            DateTime.now().toUtc()),
                                      );
                                    }
                                    context
                                        .read<FinancialsBloc>()
                                        .add(AddGoal(goal));
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('add'.tr()),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: Text('add'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
