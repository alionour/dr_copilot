import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Example goals data
    final List<_Goal> goals = [
      _Goal('increaseRevenue'.tr(),
          'achievePercentAnnualGrowth'.tr(args: ['20']), 0.65, Colors.green),
      _Goal(
          'decreaseExpenses'.tr(),
          'reduceMonthlyExpensesPercent'.tr(args: ['10']),
          0.4,
          Colors.redAccent),
      _Goal('sessionsCount'.tr(), 'reachSessionsYear'.tr(args: ['1000']), 0.8,
          Colors.blue),
      _Goal('improveNetProfit'.tr(),
          'increaseNetProfitPercent'.tr(args: ['15']), 0.5, Colors.teal),
    ];

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
                // Add Goal Section
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
                ...goals.map((goal) => _GoalCard(goal: goal)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Goal {
  final String title;
  final String description;
  final double progress; // 0.0 - 1.0
  final Color color;
  _Goal(this.title, this.description, this.progress, this.color);
}

class _GoalCard extends StatelessWidget {
  final _Goal goal;
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
            Text(
              goal.description,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 10,
              backgroundColor: goal.color.withValues(alpha:0.15),
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'progressLabelWithPercent'
                    .tr(args: [(goal.progress * 100).toStringAsFixed(0)]),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: goal.color,
                    fontSize: 14),
              ),
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
                    final _formKey = GlobalKey<FormState>();
                    String title = '';
                    String goalType = 'sessions_year';
                    Color color = Colors.teal;
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
                    return StatefulBuilder(
                      builder: (context, setState) => Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                          left: 24,
                          right: 24,
                          top: 24,
                        ),
                        child: Form(
                          key: _formKey,
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
                              TextFormField(
                                decoration: InputDecoration(
                                    labelText: 'goalDescription'.tr(),
                                    border: const OutlineInputBorder()),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'required'.tr()
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              // نسبة الإنجاز Slider
                              StatefulBuilder(
                                builder: (context, setState) {
                                  double sliderValue = 0;
                                  return StatefulBuilder(
                                    builder: (context, setSliderState) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text('progressLabel'.tr(),
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(width: 8),
                                              Text(
                                                  'progressLabelWithPercent'.tr(
                                                      args: [
                                                        sliderValue
                                                            .toStringAsFixed(0)
                                                      ]),
                                                  style: const TextStyle(
                                                      color: Colors.teal,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ],
                                          ),
                                          Slider(
                                            value: sliderValue,
                                            min: 0,
                                            max: 100,
                                            divisions: 100,
                                            label: 'progressLabelWithPercent'
                                                .tr(args: [
                                              sliderValue.toStringAsFixed(0)
                                            ]),
                                            onChanged: (v) {
                                              setSliderState(
                                                  () => sliderValue = v);
                                            },
                                            activeColor: Colors.teal,
                                            inactiveColor: Colors.teal[100],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
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
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'goalAdded'.tr(args: [title]))),
                                    );
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
