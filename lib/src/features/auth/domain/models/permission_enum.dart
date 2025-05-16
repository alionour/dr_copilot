// This file defines enums for all available permissions in the Dr Copilot app.
// Use Permission.values for iteration, or Permission.<name> for type-safe checks.

/// Enum representing all permissions in the app.
///
/// Use [AppPermission.values] to get all permissions, or [permissionToString] to get the string value.
enum AppPermission {
  // Patient management
  canViewPatient,
  canEditPatient,
  canDeletePatient,
  canAddPatient,

  // Session management
  canViewSession,
  canEditSession,
  canDeleteSession,
  canAddSession,

  // Evaluation management
  canViewEvaluation,
  canEditEvaluation,
  canDeleteEvaluation,
  canAddEvaluation,

  // Financials
  canViewFinancials,
  canEditFinancials,
  canDeleteFinancials,
  canAddFinancials,

  // Copilot chat
  canUseCopilot,

  // Calendar
  canViewCalendar,
  canEditCalendar,
  canAddCalendarEvent,
  canDeleteCalendarEvent,

  // Notifications
  canViewNotifications,
  canManageNotifications,

  // Settings
  canViewSettings,
  canEditSettings,

  // Admin
  canManageUsers,
  canAssignRoles,
  canAssignPermissions,

  // Reports/Charts
  canViewReports,
  canViewCharts,

  // Help/Support
  canViewHelp,
  canAccessSupport;

  /// Maps [AppPermission] enum to its string value (as used in Firestore and all_permissions.dart).
  String permissionToString(AppPermission permission) {
    switch (permission) {
      case AppPermission.canViewPatient:
        return 'can_view_patient';
      case AppPermission.canEditPatient:
        return 'can_edit_patient';
      case AppPermission.canDeletePatient:
        return 'can_delete_patient';
      case AppPermission.canAddPatient:
        return 'can_add_patient';
      case AppPermission.canViewSession:
        return 'can_view_session';
      case AppPermission.canEditSession:
        return 'can_edit_session';
      case AppPermission.canDeleteSession:
        return 'can_delete_session';
      case AppPermission.canAddSession:
        return 'can_add_session';
      case AppPermission.canViewEvaluation:
        return 'can_view_evaluation';
      case AppPermission.canEditEvaluation:
        return 'can_edit_evaluation';
      case AppPermission.canDeleteEvaluation:
        return 'can_delete_evaluation';
      case AppPermission.canAddEvaluation:
        return 'can_add_evaluation';
      case AppPermission.canViewFinancials:
        return 'can_view_financials';
      case AppPermission.canEditFinancials:
        return 'can_edit_financials';
      case AppPermission.canDeleteFinancials:
        return 'can_delete_financials';
      case AppPermission.canAddFinancials:
        return 'can_add_financials';
      case AppPermission.canUseCopilot:
        return 'can_use_copilot';
      case AppPermission.canViewCalendar:
        return 'can_view_calendar';
      case AppPermission.canEditCalendar:
        return 'can_edit_calendar';
      case AppPermission.canAddCalendarEvent:
        return 'can_add_calendar_event';
      case AppPermission.canDeleteCalendarEvent:
        return 'can_delete_calendar_event';
      case AppPermission.canViewNotifications:
        return 'can_view_notifications';
      case AppPermission.canManageNotifications:
        return 'can_manage_notifications';
      case AppPermission.canViewSettings:
        return 'can_view_settings';
      case AppPermission.canEditSettings:
        return 'can_edit_settings';
      case AppPermission.canManageUsers:
        return 'can_manage_users';
      case AppPermission.canAssignRoles:
        return 'can_assign_roles';
      case AppPermission.canAssignPermissions:
        return 'can_assign_permissions';
      case AppPermission.canViewReports:
        return 'can_view_reports';
      case AppPermission.canViewCharts:
        return 'can_view_charts';
      case AppPermission.canViewHelp:
        return 'can_view_help';
      case AppPermission.canAccessSupport:
        return 'can_access_support';
    }
  }

  /// Optionally, add a function to parse a string to Permission enum.
  AppPermission? permissionFromString(String value) {
    for (final perm in AppPermission.values) {
      if (permissionToString(perm) == value) return perm;
    }
    return null;
  }
}
