// This file defines all available permissions in the Dr Copilot app.
// Update this list as you add new features or access controls.

const List<String> allPermissions = [
  // Patient management
  'can_view_patient',
  'can_edit_patient',
  'can_delete_patient',
  'can_add_patient',

  // Session management
  'can_view_session',
  'can_edit_session',
  'can_delete_session',
  'can_add_session',

  // Evaluation management
  'can_view_evaluation',
  'can_edit_evaluation',
  'can_delete_evaluation',
  'can_add_evaluation',

  // Financials
  'can_view_financials',
  'can_edit_financials',
  'can_delete_financials',
  'can_add_financials',

  // Copilot chat
  'can_use_copilot',

  // Calendar
  'can_view_calendar',
  'can_edit_calendar',
  'can_add_calendar_event',
  'can_delete_calendar_event',

  // Notifications
  'can_view_notifications',
  'can_manage_notifications',

  // Settings
  'can_view_settings',
  'can_edit_settings',

  // Admin
  'can_manage_users',
  'can_assign_roles',
  'can_assign_permissions',

  // Reports/Charts
  'can_view_reports',
  'can_view_charts',

  // Help/Support
  'can_view_help',
  'can_access_support',
];
