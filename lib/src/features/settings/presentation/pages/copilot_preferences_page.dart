import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CopilotPreferencesPage extends StatelessWidget {
  const CopilotPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Check permissions
    final ownerNotifier = context.watch<OwnerNotifier>();
    final canEdit = ownerNotifier.hasPermission(AppPermission.manageSettings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copilot Preferences'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              if (!canEdit)
                Container(
                  color: Colors.amber.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.orange),
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
              _buildSectionHeader(context, 'Patient Data Requirements'),
              _buildSwitch(
                context,
                title: 'Require Age',
                keyName: 'patient.age',
                legacyKey: 'age',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'Require Gender',
                keyName: 'patient.gender',
                legacyKey: 'gender',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'Require Phone Number',
                keyName: 'patient.phone',
                legacyKey: 'phoneNumber',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'Require Address',
                keyName: 'patient.address',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'Require Alternative Phone',
                keyName: 'patient.alt_phone',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'Require Treating Doctor',
                keyName: 'patient.doctor',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'Require Occupation',
                keyName: 'patient.occupation',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              const Divider(),
              _buildSectionHeader(context, 'Session Data Requirements'),
              _buildSwitch(
                context,
                title: 'Require Session Type',
                subtitle: 'e.g., Standard, Intensive',
                keyName: 'session.type',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              const Divider(),
              _buildSectionHeader(context, 'Evaluation Data Requirements'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Doctor ID is strictly required for all sessions and evaluations.',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSwitch(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String keyName,
    String? legacyKey,
    required List<String> currentFields,
    required bool canEdit,
  }) {
    // Check if either the new key OR the legacy key is present
    final isEnabled = currentFields.contains(keyName) ||
        (legacyKey != null && currentFields.contains(legacyKey));

    return SwitchListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: isEnabled,
      onChanged: canEdit
          ? (bool value) {
              final newFields = List<String>.from(currentFields);

              if (value) {
                // Add: simple add the primary keyName
                if (!newFields.contains(keyName)) {
                  newFields.add(keyName);
                }
              } else {
                // Remove: Must remove both primary AND legacy key to fully disable
                newFields.remove(keyName);
                if (legacyKey != null) {
                  newFields.remove(legacyKey);
                }
              }

              context
                  .read<SettingsBloc>()
                  .add(UpdateCopilotFieldEvent(newFields));
            }
          : null, // Disable if not allowed
    );
  }
}
