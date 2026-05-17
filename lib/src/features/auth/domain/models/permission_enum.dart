// This file defines granular permissions for the application.
// These permissions are stored in the database for each user/member.
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';

enum AppPermission {
  // --- PATIENTS ---
  /// View patient profiles and records (Scope defined by user associations).
  viewPatients,

  /// Register a new patient.
  createPatient,

  /// Update existing patient demographic or assignment details.
  updatePatient,

  /// Soft-delete or archive a patient record.
  deletePatient,

  // --- SESSIONS ---
  /// View patient sessions (Scope defined by user associations).
  viewSessions,

  /// Schedule or record a new clinical session.
  createSession,

  /// Modify session details (notes, time, status).
  updateSession,

  /// Remove a session record.
  deleteSession,

  // --- EVALUATIONS ---
  /// View patient evaluations (Scope defined by user associations).
  viewEvaluations,

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
  /// View the list of clinic teams.
  viewTeams,

  /// Create or delete chat/collaboration teams.
  manageTeams,

  /// Create a new team.
  createTeam,

  /// Archive a team (read-only mode).
  archiveTeam,

  /// Activate an archived team.
  unarchiveTeam,

  // --- MEDICAL FILES ---
  /// View attached files (PDFs, Images) (Scope defined by user associations).
  viewMedicalFiles,

  /// Upload new documents to patient records.
  createMedicalFile,

  /// Rename or modify metadata of uploaded files.
  updateMedicalFile,

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
  /// View specialized clinical reports (Scope defined by user associations).
  viewClinicalReports,

  /// Generate a new clinical report.
  createClinicalReport,

  /// Modify an existing clinical report.
  updateClinicalReport,

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

  // --- DEPARTMENTS ---
  /// View the clinic's departments list.
  viewDepartments,

  /// Add, edit, or delete departments.
  manageDepartments,

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
  // --- TASKS ---
  /// View all tasks in the clinic
  viewAllTasks,

  /// View tasks assigned to the current user
  viewOwnTasks,

  /// Create a new task
  createTask,

  /// Edit an existing task
  updateTask,

  /// Delete a task
  deleteTask,
}


enum AppPermissionCategory {
  patientManagement,
  clinical,
  financial,
  administrative,
  scopedAccess,
  inventory,
  teamCollab,
  system,
}

extension AppPermissionExtension on AppPermission {
  AppPermissionCategory get category {
    switch (this) {
      case AppPermission.viewPatients:
      case AppPermission.createPatient:
      case AppPermission.updatePatient:
      case AppPermission.deletePatient:
        return AppPermissionCategory.patientManagement;

      case AppPermission.viewSessions:
      case AppPermission.createSession:
      case AppPermission.updateSession:
      case AppPermission.deleteSession:
      case AppPermission.viewEvaluations:
      case AppPermission.createEvaluation:
      case AppPermission.updateEvaluation:
      case AppPermission.deleteEvaluation:
      case AppPermission.viewMedicalFiles:
      case AppPermission.createMedicalFile:
      case AppPermission.updateMedicalFile:
      case AppPermission.deleteMedicalFile:
      case AppPermission.viewMedications:
      case AppPermission.addMedication:
      case AppPermission.editMedication:
      case AppPermission.deleteMedication:
      case AppPermission.viewClinicalReports:
      case AppPermission.createClinicalReport:
      case AppPermission.updateClinicalReport:
      case AppPermission.deleteClinicalReport:
      case AppPermission.viewDoctors:
      case AppPermission.manageDoctors:
        return AppPermissionCategory.clinical;

      case AppPermission.viewFinancials:
      case AppPermission.manageInvoices: // Deprecated but still in enum
      case AppPermission.viewReports:
      case AppPermission.viewCharts:
      case AppPermission.addFinancialEntry:
      case AppPermission.editFinancialEntry:
      case AppPermission.deleteFinancialEntry:
      case AppPermission.viewSubscription:
      case AppPermission.manageSubscription:
        return AppPermissionCategory.financial;

      case AppPermission.viewCalendar:
      case AppPermission.addCalendarEvent:
      case AppPermission.editCalendarEvent:
      case AppPermission.deleteCalendarEvent:
      case AppPermission.viewNotifications:
      case AppPermission.manageNotifications:
      case AppPermission.sendNotificationMessage:
      case AppPermission.sendNotificationAppointment:
      case AppPermission.sendNotificationReminder:
      case AppPermission.viewSettings:
      case AppPermission.editSettings:
      case AppPermission.manageSettings:
      case AppPermission.manageStaff:
      case AppPermission.manageUsers:
      case AppPermission.assignRoles:
      case AppPermission.assignPermissions:
      case AppPermission.viewInvitations:
      case AppPermission.sendInvitation:
      case AppPermission.revokeInvitation:
      case AppPermission.viewDepartments:
      case AppPermission.manageDepartments:
      case AppPermission.viewHelp:
      case AppPermission.accessSupport:
      case AppPermission.manageWorkingHours:
      case AppPermission.manageBookingAvailability:
        return AppPermissionCategory.administrative;

      case AppPermission.viewInventory:
      case AppPermission.manageInventory:
      case AppPermission.adjustInventoryStock:
        return AppPermissionCategory.inventory;

      case AppPermission.viewTeams:
      case AppPermission.manageTeams:
      case AppPermission.createTeam:
      case AppPermission.archiveTeam:
      case AppPermission.unarchiveTeam:
      case AppPermission.useCopilot:
        return AppPermissionCategory.teamCollab;

      case AppPermission.viewRecycleBin:
      case AppPermission.restoreRecycleBinItem:
      case AppPermission.permanentDeleteRecycleBinItem:
        return AppPermissionCategory.system;
    }
  }

  /// Returns true if this permission is logically relevant for a given role.
  /// Used to filter permissions in the UI to reduce complexity.
  bool isMeaningfulFor(AppRole role) {
    if (role == AppRole.admin) return true;

    switch (role) {
      case AppRole.doctor:
        // Doctors see clinical, administrative (except admin-only), and collab
        return category != AppPermissionCategory.financial &&
            category != AppPermissionCategory.system &&
            category != AppPermissionCategory.inventory;

      case AppRole.staff:
        // Staff see patient management, clinical (sessions/evals), general admin, and collab
        return category == AppPermissionCategory.patientManagement ||
            category == AppPermissionCategory.clinical ||
            category == AppPermissionCategory.administrative ||
            category == AppPermissionCategory.teamCollab;

      case AppRole.financial:
        // Financial see money and general admin/collab
        return category == AppPermissionCategory.financial ||
            category == AppPermissionCategory.administrative ||
            category == AppPermissionCategory.teamCollab;

      case AppRole.readonly:
        // Readonly see a very limited subset
        return this == AppPermission.viewPatients ||
            this == AppPermission.viewSessions ||
            this == AppPermission.viewCalendar ||
            this == AppPermission.viewNotifications ||
            this == AppPermission.viewHelp;

      default:
        return false;
    }
  }
}

