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
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (context, textConstraints) {
                      return Text(
                        "Hi! I'm Dr. Copilot 👋\nI'm your AI assistant. I can help you with:",
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
    bool canManagePatients = permissions.contains('can_add_patient') ||
        permissions.contains('can_edit_patient');
    bool canManageSessions = permissions.contains('can_add_session') ||
        permissions.contains('can_edit_session');
    bool canManageEvals = permissions.contains('can_add_evaluation') ||
        permissions.contains('can_edit_evaluation');

    if (canManagePatients) capabilities.add('Manage Patients 👥');
    if (canManageSessions) capabilities.add('Schedule Sessions 📅');
    if (canManageEvals) capabilities.add('Track Evaluations 📊');
    if (permissions.contains('can_view_analytics')) {
      capabilities.add('Analyze Clinic Data 📈');
    }
    if (permissions.contains('can_view_financials')) {
      capabilities.add('Check Financials 💰');
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
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.5),
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
