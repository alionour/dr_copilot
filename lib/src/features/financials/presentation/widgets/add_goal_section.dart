import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';

class AddGoalSection extends StatelessWidget {
  const AddGoalSection({super.key});

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
                  builder: (context) => const AddGoalBottomSheet(),
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

class AddGoalBottomSheet extends StatefulWidget {
  const AddGoalBottomSheet({super.key});

  @override
  State<AddGoalBottomSheet> createState() => _AddGoalBottomSheetState();
}

class _AddGoalBottomSheetState extends State<AddGoalBottomSheet> {
  final formKey = GlobalKey<FormState>();
  String title = '';
  String? description;
  String goalType = 'sessions_year';
  Color color = Colors.teal;
  final List<Map<String, String>> goalTypes = [
    {'key': 'sessions_year', 'label': 'goalTypeSessionsYear'.tr()},
    {'key': 'sessions_month', 'label': 'goalTypeSessionsMonth'.tr()},
    {'key': 'evaluations_year', 'label': 'goalTypeEvaluationsYear'.tr()},
    {'key': 'evaluations_month', 'label': 'goalTypeEvaluationsMonth'.tr()},
    {'key': 'decrease_expenses', 'label': 'goalTypeDecreaseExpenses'.tr()},
    {'key': 'increase_revenue', 'label': 'goalTypeIncreaseRevenue'.tr()},
    {'key': 'increase_profit', 'label': 'goalTypeIncreaseProfit'.tr()},
    {'key': 'custom', 'label': 'goalTypeCustom'.tr()},
  ];
  String customMetricName = '';
  String customTargetValue = '';
  String countTargetValue = '';
  String amountTargetValue = '';
  int? customYear;
  int? customMonth;
  int? selectedYear;
  int? selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
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
                          onSelected: (_) =>
                              setState(() => goalType = type['key']!),
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
                validator: (v) =>
                    v == null || v.isEmpty ? 'required'.tr() : null,
                onSaved: (v) => title = v ?? '',
              ),
              const SizedBox(height: 12),
              if (goalType == 'custom') ...[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'customMetricName'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'required'.tr() : null,
                  onSaved: (v) => customMetricName = v ?? '',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: customYear,
                        decoration: InputDecoration(
                          labelText: 'yearOptional'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('-'),
                          ),
                          ...List.generate(6, (i) {
                            final year = DateTime.now().year + i;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          })
                        ],
                        onChanged: (v) => setState(() => customYear = v),
                        validator: (v) => null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: customMonth,
                        decoration: InputDecoration(
                          labelText: 'monthOptional'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('-'),
                          ),
                          ...List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(DateFormat.MMMM(
                                            context.locale.toString())
                                        .format(DateTime(0, i + 1))),
                                  ))
                        ],
                        onChanged: (v) => setState(() => customMonth = v),
                        validator: (v) => null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'customTargetValue'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^[0-9]+([.][0-9]{0,2})?')),
                    LengthLimitingTextInputFormatter(11),
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
                  goalType == 'sessions_month' ||
                  goalType == 'evaluations_year' ||
                  goalType == 'evaluations_month') ...[
                if (goalType == 'sessions_year' ||
                    goalType == 'evaluations_year') ...[
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: 'year'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(6, (i) {
                      final year = DateTime.now().year + i;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (v) => setState(() => selectedYear = v),
                    validator: (v) => v == null ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                ],
                if (goalType == 'sessions_month' ||
                    goalType == 'evaluations_month') ...[
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      labelText: 'year'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(6, (i) {
                      final year = DateTime.now().year + i;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (v) => setState(() => selectedYear = v),
                    validator: (v) => v == null ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'month'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text(
                                  DateFormat.MMMM(context.locale.toString())
                                      .format(DateTime(0, i + 1))),
                            )),
                    onChanged: (v) => setState(() => selectedMonth = v),
                    validator: (v) => v == null ? 'required'.tr() : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'targetCount'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
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
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: InputDecoration(
                          labelText: 'yearOptional'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('-'),
                          ),
                          ...List.generate(6, (i) {
                            final year = DateTime.now().year + i;
                            return DropdownMenuItem(
                              value: year,
                              child: Text(year.toString()),
                            );
                          })
                        ],
                        onChanged: (v) => setState(() => selectedYear = v),
                        validator: (v) => null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'monthOptional'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('-'),
                          ),
                          ...List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(DateFormat.MMMM(
                                            context.locale.toString())
                                        .format(DateTime(0, i + 1))),
                                  ))
                        ],
                        onChanged: (v) => setState(() => selectedMonth = v),
                        validator: (v) => null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'targetAmount'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
                validator: (v) => null,
                onSaved: (v) => description = v,
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
                            backgroundColor: Colors.teal, radius: 8),
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
                            backgroundColor: Colors.green, radius: 8),
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
                            backgroundColor: Colors.redAccent, radius: 8),
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
                            backgroundColor: Colors.blue, radius: 8),
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
                            backgroundColor: Colors.orange, radius: 8),
                        const SizedBox(width: 8),
                        Text('colorOrange'.tr()),
                      ],
                    ),
                  ),
                ],
                onChanged: (c) => setState(() => color = c ?? Colors.teal),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    final GoalType type = goalTypeFromString(goalType);
                    GoalModelBase goal;
                    if (type == GoalType.custom) {
                      goal = CustomGoalModel(
                        id: '',
                        title: title,
                        description:
                            (description == null || description!.trim().isEmpty)
                                ? null
                                : description!.trim(),
                        goalType: type,
                        metricName: customMetricName,
                        targetValue: double.tryParse(customTargetValue) ?? 1.0,
                        color: color.toARGB32(),
                        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
                        year: customYear,
                        month: customMonth,
                        isMonthBased: customMonth != null,
                        isYearBased: customYear != null,
                        createdBy:''

                      );
                    } else if (type.isCountBased) {
                      final isYearGoal = type == GoalType.sessionsYear ||
                          type == GoalType.evaluationsYear;
                      final isMonthGoal = type == GoalType.sessionsMonth ||
                          type == GoalType.evaluationsMonth;
                      goal = CountGoalModel(
                        id: '',
                        title: title,
                        description:
                            (description == null || description!.trim().isEmpty)
                                ? null
                                : description!.trim(),
                        goalType: type,
                        targetCount: int.tryParse(countTargetValue) ?? 1,
                        color: color.toARGB32(),
                        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
                        year: (isYearGoal || isMonthGoal) ? selectedYear : null,
                        month: isMonthGoal ? selectedMonth : null,
                        createdBy:''

                      );
                    } else {
                      goal = AmountGoalModel(
                        id: '',
                        title: title,
                        description:
                            (description == null || description!.trim().isEmpty)
                                ? null
                                : description!.trim(),
                        goalType: type,
                        targetAmount: double.tryParse(amountTargetValue) ?? 1.0,
                        color: color.toARGB32(),
                        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
                        year: selectedYear,
                        month: selectedMonth,
                        createdBy:''

                      );
                    }
                    context.read<FinancialsBloc>().add(AddGoal(goal));
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
  }
}
