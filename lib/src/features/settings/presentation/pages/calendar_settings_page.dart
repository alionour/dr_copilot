import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class CalendarSettingsPage extends StatelessWidget {
  const CalendarSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Weekday names starting from Monday
    // DateTime.monday = 1, ... DateTime.sunday = 7
    final weekDays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];

    // Check permissions
    final ownerNotifier = context.watch<OwnerNotifier>();
    final canEdit = ownerNotifier.hasPermission(AppPermission.manageSettings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final workingDays = state.workingDays;

          return ListView(
            children: [
              if (!canEdit)
                Container(
                  color: Colors.amber.withOpacity(0.1),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Only admins can modify these settings.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Working Days',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: weekDays.map((day) {
                    // Get localized day name
                    // We use a dummy date that corresponds to the day of week
                    // Jan 1 2024 is Monday
                    final dummyDate = DateTime(2024, 1, day);
                    final dayName = DateFormat('EEEE').format(dummyDate);

                    final isWorkingDay = workingDays.contains(day);

                    return CheckboxListTile(
                      title: Text(dayName),
                      value: isWorkingDay,
                      onChanged: canEdit
                          ? (bool? value) {
                              List<int> newWorkingDays = List.from(workingDays);
                              if (value == true) {
                                if (!newWorkingDays.contains(day)) {
                                  newWorkingDays.add(day);
                                }
                              } else {
                                newWorkingDays.remove(day);
                              }
                              // Sort for consistency
                              newWorkingDays.sort();

                              context.read<SettingsBloc>().add(
                                    UpdateWorkingDaysEvent(newWorkingDays),
                                  );
                            }
                          : null, // Disable if not allowed
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'These settings affect the "Work Week" view in the calendar.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
