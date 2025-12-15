import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class GoalDescriptionField extends StatelessWidget {
  final FormFieldSetter<String?> onSaved;
  const GoalDescriptionField({super.key, required this.onSaved});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'goalDescription'.tr(),
        border: const OutlineInputBorder(),
      ),
      validator: (v) => null,
      onSaved: onSaved,
    );
  }
}

