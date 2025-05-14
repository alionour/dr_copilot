import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/goal_type_chips.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/goal_title_field.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/custom_goal_fields.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/count_goal_fields.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/amount_goal_fields.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/goal_description_field.dart';
import 'package:dr_copilot/src/features/financials/presentation/widgets/goals_page_widgets/goal_color_dropdown.dart';

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
              GoalTypeChips(
                goalTypes: goalTypes,
                selectedGoalType: goalType,
                onChanged: (type) => setState(() => goalType = type),
              ),
              const SizedBox(height: 16),
              GoalTitleField(
                onSaved: (v) => title = v ?? '',
                validator: (v) =>
                    v == null || v.isEmpty ? 'required'.tr() : null,
              ),
              const SizedBox(height: 12),
              if (goalType == 'custom')
                CustomGoalFields(
                  onMetricNameSaved: (v) => customMetricName = v ?? '',
                  onTargetValueSaved: (v) => customTargetValue = v ?? '',
                  customYear: customYear,
                  customMonth: customMonth,
                  onYearChanged: (v) => setState(() => customYear = v),
                  onMonthChanged: (v) => setState(() => customMonth = v),
                )
              else if (goalType == 'sessions_year' ||
                  goalType == 'sessions_month' ||
                  goalType == 'evaluations_year' ||
                  goalType == 'evaluations_month')
                CountGoalFields(
                  goalType: goalType,
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  onYearChanged: (v) => setState(() => selectedYear = v),
                  onMonthChanged: (v) => setState(() => selectedMonth = v),
                  onTargetCountSaved: (v) => countTargetValue = v ?? '',
                )
              else if (goalType == 'decrease_expenses' ||
                  goalType == 'increase_revenue' ||
                  goalType == 'increase_profit')
                AmountGoalFields(
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  onYearChanged: (v) => setState(() => selectedYear = v),
                  onMonthChanged: (v) => setState(() => selectedMonth = v),
                  onTargetAmountSaved: (v) => amountTargetValue = v ?? '',
                ),
              // Removed unnecessary disabled TextFormField that caused extra spacing
              GoalDescriptionField(
                onSaved: (v) => description = v,
              ),
              const SizedBox(height: 12),
              GoalColorDropdown(
                value: color,
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
