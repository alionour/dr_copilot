// This file defines all available roles and their mapped permissions in the Dr AI app.
// Update this list as you add new roles or change role permissions.

/// Central mapping of roles to permissions.
///
/// Example usage:
///   rolePermissions['admin']  // returns all permissions for admin
///   rolePermissions['doctor'] // returns all permissions for doctor
const Map<String, List<String>> rolePermissions = {
  // Admin: full access
  'admin': [
    'can_view_patient',
    'can_edit_patient',
    'can_delete_patient',
    'can_add_patient',
    'can_view_session',
    'can_edit_session',
    'can_delete_session',
    'can_add_session',
    'can_view_evaluation',
    'can_edit_evaluation',
    'can_delete_evaluation',
    'can_add_evaluation',
    'can_view_financials',
    'can_edit_financials',
    'can_delete_financials',
    'can_add_financials',
    'can_use_copilot',
    'can_view_calendar',
    'can_edit_calendar',
    'can_add_calendar_event',
    'can_delete_calendar_event',
    'can_view_notifications',
    'can_manage_notifications',
    'can_send_notification_message',
    'can_send_notification_appointment',
    'can_send_notification_reminder',
    'can_view_settings',
    'can_edit_settings',
    'can_manage_users',
    'can_assign_roles',
    'can_assign_permissions',
    'can_view_reports',
    'can_view_charts',
    'can_view_help',
    'can_access_support',
    'can_create_team',
    'can_archive_team',
    'can_unarchive_team',
  ],

  // Doctor: typical clinical access
  'doctor': [
    'can_view_patient',
    'can_edit_patient',
    'can_add_patient',
    'can_view_session',
    'can_edit_session',
    'can_add_session',
    'can_view_evaluation',
    'can_edit_evaluation',
    'can_add_evaluation',
    'can_view_calendar',
    'can_edit_calendar',
    'can_add_calendar_event',
    'can_view_notifications',
    'can_send_notification_message',
    'can_send_notification_appointment',
    'can_send_notification_reminder',
    'can_use_copilot',
    'can_view_help',
    'can_access_support',
  ],

  // Staff: limited access
  'staff': [
    'can_view_patient',
    'can_add_patient',
    'can_view_session',
    'can_add_session',
    'can_view_evaluation',
    'can_add_evaluation',
    'can_view_calendar',
    'can_view_notifications',
    'can_send_notification_appointment',
    'can_send_notification_reminder',
    'can_use_copilot',
    'can_view_help',
  ],

  // Financial: access to financials and reports
  'financial': [
    'can_view_financials',
    'can_edit_financials',
    'can_add_financials',
    'can_view_reports',
    'can_view_charts',
  ],

  // Readonly: view-only access
  'readonly': [
    'can_view_patient',
    'can_view_session',
    'can_view_evaluation',
    'can_view_financials',
    'can_view_calendar',
    'can_view_notifications',
    'can_view_settings',
    'can_view_reports',
    'can_view_help',
  ],
};
