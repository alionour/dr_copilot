import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class CustomGoalFields extends StatelessWidget {
  final FormFieldSetter<String> onMetricNameSaved;
  final FormFieldSetter<String> onTargetValueSaved;
  final int? customYear;
  final int? customMonth;
  final ValueChanged<int?> onYearChanged;
  final ValueChanged<int?> onMonthChanged;

  const CustomGoalFields({
    super.key,
    required this.onMetricNameSaved,
    required this.onTargetValueSaved,
    required this.customYear,
    required this.customMonth,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          decoration: InputDecoration(
            labelText: 'customMetricName'.tr(),
            border: const OutlineInputBorder(),
          ),
          validator: (v) => v == null || v.isEmpty ? 'required'.tr() : null,
          onSaved: onMetricNameSaved,
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
                onChanged: onYearChanged,
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
            labelText: 'customTargetValue'.tr(),
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          onSaved: onTargetValueSaved,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
