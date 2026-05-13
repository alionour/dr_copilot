// This file defines granular permissions for the application.
// These permissions are stored in the database for each user/member.

enum AppPermission {
  // --- PATIENTS ---
  /// View the complete list of patients in the clinic.
  viewAllPatients,

  /// View only patients assigned strictly to the current user (if applicable).
  viewOwnPatients,

  /// Register a new patient in the clinic.
  createPatient,

  /// Update existing patient demographic or assignment details.
  updatePatient,

  /// Soft-delete or archive a patient record.
  deletePatient,

  // --- SESSIONS ---
  /// View sessions across the entire clinic.
  viewAllSessions,

  /// View sessions where the current user is the provider.
  viewOwnSessions,

  /// Schedule or record a new clinical session.
  createSession,

  /// Modify session details (notes, time, status).
  updateSession,

  /// Remove a session record.
  deleteSession,

  // --- EVALUATIONS ---
  /// View clinical evaluations/assessments for all patients.
  viewAllEvaluations,

  /// View evaluations performed by the current user.
  viewOwnEvaluations,

  /// Perform and record a new evaluation.
  createEvaluation,

  /// Edit an existing evaluation.
  updateEvaluation,

  /// Delete an evaluation record.
  deleteEvaluation,

  // --- FINANCIALS ---
  /// Access the financial dashboard, view invoices, and transaction history.
  viewFinancials,

  /// @Deprecated('Use add/edit/deleteFinancialEntry instead')
  manageInvoices,

  /// View aggregated financial reports and summaries.
  viewReports,

  /// View visual financial charts and analytics.
  viewCharts,

  // --- CALENDAR ---
  /// View the clinic's master calendar or appointment book.
  viewCalendar,

  /// Schedule items on the global calendar.
  addCalendarEvent,

  /// Reschedule or modify calendar events.
  editCalendarEvent,

  /// Cancel or remove calendar events.
  deleteCalendarEvent,

  // --- COPILOT AI ---
  /// Access and interact with the AI assistant.
  useCopilot,

  // --- NOTIFICATIONS ---
  /// View the notification center history.
  viewNotifications,

  /// Configure notification settings.
  manageNotifications,

  /// Send a manual message notification to patients/staff.
  sendNotificationMessage,

  /// Send appointment reminders manually.
  sendNotificationAppointment,

  /// Check or send general reminders.
  sendNotificationReminder,

  // --- SETTINGS ---
  /// View clinic configuration and settings.
  viewSettings,

  /// Modify clinic configuration (e.g., logo, operating hours).
  editSettings,

  // --- ADMIN & STAFF ---
  /// Add, remove, or edit staff member profiles.
  manageStaff,

  /// Manage user accounts (invites, role changes).
  manageUsers,

  /// Change the role of a user (e.g., Staff to Doctor).
  assignRoles,

  /// Grant or revoke specific permissions for a user.
  assignPermissions,

  /// Access critical system-wide settings (Owner level).
  manageSettings,

  // --- TEAMS ---
  /// Create or delete chat/collaboration teams.
  manageTeams,

  /// Create a new team.
  createTeam,

  /// Archive a team (read-only mode).
  archiveTeam,

  /// Activate an archived team.
  unarchiveTeam,

  // --- MEDICAL FILES ---
  /// View attached files (PDFs, Images) in patient records.
  viewMedicalFiles,

  /// Upload new documents to patient records.
  addMedicalFile,

  /// Rename or modify metadata of uploaded files.
  editMedicalFile,

  /// Remove files from patient records.
  deleteMedicalFile,

  // --- MEDICATIONS ---
  /// View the clinic's medication list/formulary.
  viewMedications,

  /// Add new drugs to the formulary.
  addMedication,

  /// Edit details of existing medications.
  editMedication,

  /// Remove medications from the formulary.
  deleteMedication,

  // --- RECYCLE BIN ---
  /// Access deleted items pending permanent removal.
  viewRecycleBin,

  /// Restore a deleted item to active status.
  restoreRecycleBinItem,

  /// Permanently destroy data (GDPR/Compliance).
  permanentDeleteRecycleBinItem,

  // --- FINANCIALS (GRANULAR) ---
  /// Record a new financial transaction (invoice/payment).
  addFinancialEntry,

  /// Correct or update a financial record.
  editFinancialEntry,

  /// Void or remove a financial record.
  deleteFinancialEntry,

  // --- CLINICAL REPORTS ---
  /// View specialized clinical reports (Phase 2 feature).
  viewClinicalReports,

  /// Generate a new clinical report.
  addClinicalReport,

  /// Modify an existing clinical report.
  editClinicalReport,

  /// Delete a clinical report.
  deleteClinicalReport,

  // --- DOCTORS DIRECTORY ---
  /// View the public list of doctors in the clinic.
  viewDoctors,

  /// Add or edit doctor profiles in the directory.
  manageDoctors,

  // --- INVITATIONS ---
  /// View pending and sent invitations.
  viewInvitations,

  /// Invite a new user to join the clinic via email.
  sendInvitation,

  /// Cancel a sent invitation before it is accepted.
  revokeInvitation,

  // --- SUBSCRIPTION ---
  /// View current billing plan and usage quotas.
  viewSubscription,

  /// Upgrade, downgrade, or cancel the subscription.
  manageSubscription,

  // --- INVENTORY ---
  /// View the inventory list and stock levels.
  viewInventory,

  /// Add, edit, or delete inventory items.
  manageInventory,

  /// Adjust stock quantities (add/remove stock).
  adjustInventoryStock,

  // --- HELP & SUPPORT ---
  /// Access help documentation/FAQ.
  viewHelp,

  /// Contact support or open tickets.
  accessSupport,

  // --- SCHEDULING ---
  /// Edit working hours and appointment duration/price.
  manageWorkingHours,

  /// Enable or disable booking availability for doctors.
  manageBookingAvailability,

  // --- DOCTOR-SCOPED ACCESS ---
  /// View patients scoped to linked doctors only.
  viewPatientsByDoctor,

  /// Create, edit, or delete patients for linked doctors.
  managePatientsForDoctor,

  /// View medical files for patients of linked doctors.
  viewMedicalFilesByDoctor,

  /// Add, edit, or delete medical files for patients of linked doctors.
  manageMedicalFilesForDoctor,
}
