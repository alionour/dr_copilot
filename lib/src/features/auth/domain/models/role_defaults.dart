import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';

/// Defines the default permissions for each role.
/// This is used for:
/// 1. Initial migration of existing users.
/// 2. Assigning permissions when adding new staff members.
class RoleDefaults {
  static List<AppPermission> getPermissionsForRole(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return [
          ...AppPermission.values,
          AppPermission.sendNotificationMessage,
          AppPermission.sendNotificationAppointment,
          AppPermission.sendNotificationReminder,
        ];

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
          AppPermission.sendNotificationMessage,
          AppPermission.sendNotificationAppointment,
          AppPermission.sendNotificationReminder,
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
          AppPermission.sendNotificationAppointment,
          AppPermission.sendNotificationReminder,
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

  static List<NotificationTargetType> getAllowedNotificationTargets(
    AppRole role,
  ) {
    if (role == AppRole.admin) {
      return [
        NotificationTargetType.ownerClinics,
        NotificationTargetType.specificClinic,
        NotificationTargetType.specificRoles,
        NotificationTargetType.customTeam,
      ];
    }

    // For Doctor, Staff, Financial - they don't "own" clinics, so no ownerClinics
    return [
      NotificationTargetType.specificClinic,
      NotificationTargetType.specificRoles,
      NotificationTargetType.customTeam,
    ];
  }
}
