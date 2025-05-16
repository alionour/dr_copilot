// This file defines enums for all available permissions in the Dr Copilot app.
// Use Permission.values for iteration, or Permission.<name> for type-safe checks.

/// Enum representing all permissions in the app.
///
/// Use [Permission.values] to get all permissions, or [permissionToString] to get the string value.
enum Permission {
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

  /// Maps [Permission] enum to its string value (as used in Firestore and all_permissions.dart).
  String permissionToString(Permission permission) {
    switch (permission) {
      case Permission.canViewPatient:
        return 'can_view_patient';
      case Permission.canEditPatient:
        return 'can_edit_patient';
      case Permission.canDeletePatient:
        return 'can_delete_patient';
      case Permission.canAddPatient:
        return 'can_add_patient';
      case Permission.canViewSession:
        return 'can_view_session';
      case Permission.canEditSession:
        return 'can_edit_session';
      case Permission.canDeleteSession:
        return 'can_delete_session';
      case Permission.canAddSession:
        return 'can_add_session';
      case Permission.canViewEvaluation:
        return 'can_view_evaluation';
      case Permission.canEditEvaluation:
        return 'can_edit_evaluation';
      case Permission.canDeleteEvaluation:
        return 'can_delete_evaluation';
      case Permission.canAddEvaluation:
        return 'can_add_evaluation';
      case Permission.canViewFinancials:
        return 'can_view_financials';
      case Permission.canEditFinancials:
        return 'can_edit_financials';
      case Permission.canDeleteFinancials:
        return 'can_delete_financials';
      case Permission.canAddFinancials:
        return 'can_add_financials';
      case Permission.canUseCopilot:
        return 'can_use_copilot';
      case Permission.canViewCalendar:
        return 'can_view_calendar';
      case Permission.canEditCalendar:
        return 'can_edit_calendar';
      case Permission.canAddCalendarEvent:
        return 'can_add_calendar_event';
      case Permission.canDeleteCalendarEvent:
        return 'can_delete_calendar_event';
      case Permission.canViewNotifications:
        return 'can_view_notifications';
      case Permission.canManageNotifications:
        return 'can_manage_notifications';
      case Permission.canViewSettings:
        return 'can_view_settings';
      case Permission.canEditSettings:
        return 'can_edit_settings';
      case Permission.canManageUsers:
        return 'can_manage_users';
      case Permission.canAssignRoles:
        return 'can_assign_roles';
      case Permission.canAssignPermissions:
        return 'can_assign_permissions';
      case Permission.canViewReports:
        return 'can_view_reports';
      case Permission.canViewCharts:
        return 'can_view_charts';
      case Permission.canViewHelp:
        return 'can_view_help';
      case Permission.canAccessSupport:
        return 'can_access_support';
    }
  }

  /// Optionally, add a function to parse a string to Permission enum.
  Permission? permissionFromString(String value) {
    for (final perm in Permission.values) {
      if (permissionToString(perm) == value) return perm;
    }
    return null;
  }
}
