// This file defines granular permissions for the application.
// These permissions are stored in the database for each user/member.

enum AppPermission {
  // Patients
  viewAllPatients,
  viewOwnPatients,
  createPatient,
  updatePatient,
  deletePatient,

  // Sessions
  viewAllSessions,
  viewOwnSessions,
  createSession,
  updateSession,
  deleteSession,

  // Evaluations
  viewAllEvaluations,
  viewOwnEvaluations,
  createEvaluation,
  updateEvaluation,
  deleteEvaluation,

  // Financials
  viewFinancials,
  manageInvoices,
  viewReports,
  viewCharts,

  // Calendar
  viewCalendar,
  addCalendarEvent,
  editCalendarEvent,
  deleteCalendarEvent,

  // Copilot
  useCopilot,

  // Notifications
  viewNotifications,
  manageNotifications,
  sendNotificationMessage,
  sendNotificationAppointment,
  sendNotificationReminder,

  // Settings
  viewSettings,
  editSettings,

  // Admin
  manageStaff,
  manageUsers,
  assignRoles,
  assignPermissions,
  manageSettings,

  // Teams
  manageTeams,
  createTeam,
  archiveTeam,
  unarchiveTeam,

  // Help & Support
  viewHelp,
  accessSupport,
}
