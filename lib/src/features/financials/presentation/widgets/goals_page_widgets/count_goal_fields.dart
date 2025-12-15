import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class CountGoalFields extends StatelessWidget {
  final String goalType;
  final int? selectedYear;
  final int? selectedMonth;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onMonthChanged;
  final FormFieldSetter<String> onTargetCountSaved;

  const CountGoalFields({
    super.key,
    required this.goalType,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onTargetCountSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (goalType == 'sessions_year' || goalType == 'evaluations_year') ...[
          DropdownButtonFormField<int>(
            initialValue: selectedYear,
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
            onChanged: onYearChanged,
            validator: (v) => v == null ? 'required'.tr() : null,
          ),
          const SizedBox(height: 12),
        ],
        if (goalType == 'sessions_month' ||
            goalType == 'evaluations_month') ...[
          DropdownButtonFormField<int>(
            initialValue: selectedYear,
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
            onChanged: onYearChanged,
            validator: (v) => v == null ? 'required'.tr() : null,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: selectedMonth,
            decoration: InputDecoration(
              labelText: 'month'.tr(),
              border: const OutlineInputBorder(),
            ),
            items: List.generate(
                12,
                (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(DateFormat.MMMM(context.locale.toString())
                          .format(DateTime(0, i + 1))),
                    )),
            onChanged: onMonthChanged,
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
          onSaved: onTargetCountSaved,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

