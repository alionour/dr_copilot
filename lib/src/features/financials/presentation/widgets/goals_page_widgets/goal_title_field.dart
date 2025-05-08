import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class GoalTitleField extends StatelessWidget {
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String>? validator;
  const GoalTitleField({super.key, required this.onSaved, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'goalTitle'.tr(),
        border: const OutlineInputBorder(),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }
}
