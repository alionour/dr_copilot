import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
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
        title: const Text('copilotPreferences').tr(),
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
                          'onlyAdminsModifySettings'.tr(),
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
              _buildSectionHeader(context, 'patientDataRequirements'.tr()),
              _buildSwitch(
                context,
                title: 'requireAge'.tr(),
                keyName: 'patient.age',
                legacyKey: 'age',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'requireGender'.tr(),
                keyName: 'patient.gender',
                legacyKey: 'gender',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'requirePhoneNumber'.tr(),
                keyName: 'patient.phone',
                legacyKey: 'phoneNumber',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'requireAddress'.tr(),
                keyName: 'patient.address',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'requireAlternativePhone'.tr(),
                keyName: 'patient.alt_phone',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'requireTreatingDoctor'.tr(),
                keyName: 'patient.doctor',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              _buildSwitch(
                context,
                title: 'requireOccupation'.tr(),
                keyName: 'patient.occupation',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              const Divider(),
              _buildSectionHeader(context, 'sessionDataRequirements'.tr()),
              _buildSwitch(
                context,
                title: 'requireSessionType'.tr(),
                subtitle: 'sessionTypeExample'.tr(),
                keyName: 'session.type',
                currentFields: state.copilotRequiredFields,
                canEdit: canEdit,
              ),
              const Divider(),
              _buildSectionHeader(context, 'evaluationDataRequirements'.tr()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'doctorIdRequiredWarning'.tr(),
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
              const Divider(),
              _buildSectionHeader(context, 'aiModelPreferences'.tr()),
              SwitchListTile(
                title: const Text('usePremiumModels').tr(),
                subtitle: const Text(
                  'usePremiumModelsDescription',
                ).tr(),
                value: state.usePremiumModels,
                onChanged: canEdit
                    ? (_) {
                        context
                            .read<SettingsBloc>()
                            .add(TogglePremiumModelsEvent());
                      }
                    : null,
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
