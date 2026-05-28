import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class EmptyChatPlaceholder extends StatelessWidget {
  final List<String>? userPermissions;

  const EmptyChatPlaceholder({super.key, this.userPermissions});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth * 0.9;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth < 600 ? maxWidth : 600,
            ),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, textConstraints) {
                      return Text(
                        'copilotGreeting'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          foreground: Paint()
                            ..shader = LinearGradient(
                              colors: const <Color>[
                                Color(0xFF6A11CB),
                                Color(0xFF2575FC),
                              ],
                            ).createShader(
                              Rect.fromLTWH(
                                0.0,
                                0.0,
                                textConstraints.maxWidth,
                                100.0,
                              ),
                            ),
                        ),
                      );
                    },
                  ),
                  if (userPermissions != null &&
                      userPermissions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCapabilitiesList(context, userPermissions!),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCapabilitiesList(
      BuildContext context, List<String> permissions) {
    // Filter and map permissions to readable capabilities
    final capabilities = <String>[];

    // Group permissions into actionable items
    bool canManagePatients = permissions.contains('createPatient') ||
        permissions.contains('updatePatient');
    bool canManageSessions = permissions.contains('createSession') ||
        permissions.contains('updateSession');
    bool canManageEvals = permissions.contains('createEvaluation') ||
        permissions.contains('updateEvaluation');

    if (canManagePatients) capabilities.add('copilotManagePatients'.tr());
    if (canManageSessions) capabilities.add('copilotScheduleSessions'.tr());
    if (canManageEvals) capabilities.add('copilotTrackEvaluations'.tr());
    if (permissions.contains('viewCharts') ||
        permissions.contains('viewReports')) {
      capabilities.add('copilotAnalyzeData'.tr());
    }
    if (permissions.contains('viewFinancials')) {
      capabilities.add('copilotCheckFinancials'.tr());
    }

    if (capabilities.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: capabilities.map((cap) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                cap,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
