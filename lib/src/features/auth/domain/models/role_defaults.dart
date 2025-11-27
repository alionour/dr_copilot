import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';

/// Defines the default permissions for each role.
/// This is used for:
/// 1. Initial migration of existing users.
/// 2. Assigning permissions when adding new staff members.
class RoleDefaults {
  static List<AppPermission> getPermissionsForRole(AppRole role) {
    switch (role) {
      case AppRole.superAdmin:
      case AppRole.admin:
        return AppPermission.values; // Admin gets everything

      case AppRole.doctor:
        return [
          AppPermission.viewAllPatients,
          AppPermission.createPatient,
          AppPermission.updatePatient,
          AppPermission
              .viewAllSessions, // Doctor usually sees all sessions in clinic context
          AppPermission.createSession,
          AppPermission.updateSession,
          AppPermission.viewAllEvaluations,
          AppPermission.createEvaluation,
          AppPermission.updateEvaluation,
          AppPermission.viewCalendar,
          AppPermission.addCalendarEvent,
          AppPermission.editCalendarEvent,
          AppPermission.useCopilot,
          AppPermission.viewNotifications,
        ];

      case AppRole.staff:
        return [
          AppPermission.viewAllPatients,
          AppPermission.createPatient,
          AppPermission.updatePatient,
          AppPermission.viewAllSessions,
          AppPermission.viewCalendar,
          AppPermission.addCalendarEvent, // Staff often schedule
          AppPermission.viewNotifications,
        ];

      case AppRole.financial:
        return [
          AppPermission.viewFinancials,
          AppPermission.manageInvoices,
          AppPermission.viewReports,
          AppPermission.viewCharts,
          AppPermission.viewNotifications,
        ];

      case AppRole.readonly:
        return [
          AppPermission.viewAllPatients,
          AppPermission.viewAllSessions,
          AppPermission.viewCalendar,
        ];
    }
  }
}
