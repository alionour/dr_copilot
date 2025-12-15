import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class GoalColorDropdown extends StatelessWidget {
  final Color value;
  final ValueChanged<Color?> onChanged;
  const GoalColorDropdown(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Color>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'goalColor'.tr(),
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem(
          value: Colors.teal,
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.teal, radius: 8),
              const SizedBox(width: 8),
              Text('colorTeal'.tr()),
            ],
          ),
        ),
        DropdownMenuItem(
          value: Colors.green,
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.green, radius: 8),
              const SizedBox(width: 8),
              Text('colorGreen'.tr()),
            ],
          ),
        ),
        DropdownMenuItem(
          value: Colors.redAccent,
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.redAccent, radius: 8),
              const SizedBox(width: 8),
              Text('colorRed'.tr()),
            ],
          ),
        ),
        DropdownMenuItem(
          value: Colors.blue,
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.blue, radius: 8),
              const SizedBox(width: 8),
              Text('colorBlue'.tr()),
            ],
          ),
        ),
        DropdownMenuItem(
          value: Colors.orange,
          child: Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.orange, radius: 8),
              const SizedBox(width: 8),
              Text('colorOrange'.tr()),
            ],
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

