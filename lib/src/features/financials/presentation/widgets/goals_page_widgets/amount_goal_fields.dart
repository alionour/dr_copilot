import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class AmountGoalFields extends StatelessWidget {
  final int? selectedYear;
  final int? selectedMonth;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onMonthChanged;
  final FormFieldSetter<String> onTargetAmountSaved;

  const AmountGoalFields({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onTargetAmountSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                onChanged: onYearChanged,
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
                            child: Text(
                                DateFormat.MMMM(context.locale.toString())
                                    .format(DateTime(0, i + 1))),
                          ))
                ],
                onChanged: onMonthChanged,
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
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          onSaved: onTargetAmountSaved,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
