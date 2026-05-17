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
          AppPermission.viewPatients,
          AppPermission.createPatient,
          AppPermission.updatePatient,
          AppPermission.viewSessions,
          AppPermission.createSession,
          AppPermission.updateSession,
          AppPermission.viewEvaluations,
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
          AppPermission.viewDepartments,
          // Doctors can create teams; they see their own teams by default without viewTeams.
          AppPermission.createTeam,
        ];

      case AppRole.staff:
        return [
          AppPermission.viewPatients,
          AppPermission.createPatient,
          AppPermission.updatePatient,
          AppPermission.viewSessions,
          AppPermission.createEvaluation,
          AppPermission.viewEvaluations,
          AppPermission.viewDoctors,
          AppPermission.viewCalendar,
          AppPermission.addCalendarEvent,
          AppPermission.viewNotifications,
          AppPermission.sendNotificationAppointment,
          AppPermission.sendNotificationReminder,
          AppPermission.viewDepartments,
          // Staff can create teams; they see their own teams by default without viewTeams.
          AppPermission.createTeam,
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
          AppPermission.viewPatients,
          AppPermission.viewSessions,
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
