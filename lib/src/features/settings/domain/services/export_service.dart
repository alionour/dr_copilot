import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/settings/domain/repositories/export_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ExportProgressCallback =
    void Function(double progress, String category);

/// Service responsible for orchestrating the user data export process.
///
/// This service coordinates fetching data from multiple sources via the
/// [ExportRepository], aggregates it into a structured format, and saves
/// it as a JSON file.
class ExportService {
  final ExportRepository repository;
  static const String _lastExportKey = 'last_export_timestamp';
  static const int _exportCooldownDays = 7;

  ExportService({required this.repository});

  /// Checks if user can export based on rate limit (once per week)
  Future<Map<String, dynamic>> canExport() async {
    final prefs = await SharedPreferences.getInstance();
    final lastExportTimestamp = prefs.getInt(_lastExportKey);

    if (lastExportTimestamp == null) {
      return {'canExport': true};
    }

    final lastExportDate = DateTime.fromMillisecondsSinceEpoch(
      lastExportTimestamp,
    );
    final now = DateTime.now();
    final daysSinceLastExport = now.difference(lastExportDate).inDays;

    if (daysSinceLastExport < _exportCooldownDays) {
      final daysRemaining = _exportCooldownDays - daysSinceLastExport;
      final nextExportDate = lastExportDate.add(
        Duration(days: _exportCooldownDays),
      );
      return {
        'canExport': false,
        'daysRemaining': daysRemaining,
        'nextExportDate': nextExportDate,
        'lastExportDate': lastExportDate,
      };
    }

    return {'canExport': true};
  }

  /// Records the current export timestamp
  Future<void> _recordExportTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastExportKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Checks if user has permission to export based on their role
  /// Currently: Only admins can export
  /// Future: Doctors can export their own data
  Future<Map<String, dynamic>> canUserExport(
    String userId,
    String primaryClinicId,
  ) async {
    try {
      // Import UserModel here to avoid circular dependencies
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        return {'canExport': false, 'reason': 'User not found'};
      }

      // Get user's role in primary clinic
      final memberDoc = await firestore
          .collection('clinics')
          .doc(primaryClinicId)
          .collection('members')
          .doc(userId)
          .get();

      if (!memberDoc.exists) {
        return {
          'canExport': false,
          'reason': 'You are not a member of any clinic',
        };
      }

      final role = (memberDoc.data()?['role'] as String?)?.toLowerCase();

      // Check if user has export permission
      // Admin and super_admin can export
      if (role == 'admin' || role == 'super_admin') {
        return {
          'canExport': true,
          'role': role,
          'exportScope': 'full', // Full clinic data
        };
      }

      // Future: Doctor can export their own data
      if (role == 'doctor') {
        return {
          'canExport': false, // Disabled for now
          'reason': 'Doctor export functionality coming soon',
          'role': role,
          // When enabled: 'exportScope': 'own_data',
        };
      }

      // All other roles (staff, readonly, financial) cannot export
      return {
        'canExport': false,
        'reason':
            'You do not have permission to export data. Only administrators can export clinic data.',
        'role': role,
      };
    } catch (e) {
      debugPrint('[ExportService] Error checking user permissions: $e');
      return {'canExport': false, 'reason': 'Error checking permissions: $e'};
    }
  }

  /// Exports all user data to a JSON file.
  ///
  /// [userId] - The ID of the user whose data to export
  /// [userEmail] - The email of the user (for invitations lookup)
  /// [onProgress] - Optional callback for progress updates
  ///
  /// Returns the file path of the generated export file.
  ///
  /// Throws an exception if the export fails.
  Future<String> exportAllUserData(
    String userId,
    String userEmail, {
    ExportProgressCallback? onProgress,
  }) async {
    try {
      debugPrint('[ExportService] Starting export for user: $userId');

      // Generate the export data
      final exportData = await _generateExportData(
        userId,
        userEmail,
        onProgress,
      );

      // Generate and save the file
      final filePath = await _generateExportFile(exportData, userId);

      // Record the export time
      await _recordExportTime();

      debugPrint('[ExportService] Export completed: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('[ExportService] Export failed: $e');
      rethrow;
    }
  }

  /// Generates the complete export data structure.
  Future<Map<String, dynamic>> _generateExportData(
    String userId,
    String userEmail,
    ExportProgressCallback? onProgress,
  ) async {
    final totalSteps = 20; // Total number of data categories to fetch
    var currentStep = 0;

    void updateProgress(String category) {
      currentStep++;
      final progress = currentStep / totalSteps;
      onProgress?.call(progress, category);
      debugPrint(
        '[ExportService] Progress: ${(progress * 100).toStringAsFixed(1)}% - $category',
      );
    }

    // Fetch user profile first
    updateProgress('User Profile');
    final userProfile = await repository.fetchUserProfile(userId);

    if (userProfile == null) {
      throw Exception('User profile not found');
    }

    // Extract clinic IDs for subsequent queries
    final clinicIds =
        (userProfile['clinicIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Fetch clinic information
    updateProgress('Clinics');
    final clinics = await repository.fetchClinics(clinicIds);

    // Fetch patients
    updateProgress('Patients');
    final patients = await repository.fetchPatients(userId, clinicIds);
    final patientIds = patients.map((p) => p['id'].toString()).toList();

    // Fetch clinical reports
    updateProgress('Clinical Reports');
    final clinicalReports = await repository.fetchClinicalReports(patientIds);

    // Fetch sessions
    updateProgress('Sessions');
    final sessions = await repository.fetchSessions(userId, clinicIds);

    // Fetch evaluations
    updateProgress('Evaluations');
    final evaluations = await repository.fetchEvaluations(patientIds);

    // Fetch invoices
    updateProgress('Invoices');
    final invoices = await repository.fetchInvoices(userId, clinicIds);
    final invoiceIds = invoices.map((i) => i['id'].toString()).toList();

    // Fetch transactions
    updateProgress('Transactions');
    final transactions = await repository.fetchTransactions(invoiceIds);

    // Fetch bills
    updateProgress('Bills');
    final bills = await repository.fetchBills(userId);

    // Fetch scheduled bills
    updateProgress('Scheduled Bills');
    final scheduledBills = await repository.fetchScheduledBills(userId);

    // Fetch financial goals
    updateProgress('Financial Goals');
    final goals = await repository.fetchGoals(userId);

    // Fetch currency profiles
    updateProgress('Currency Profiles');
    final currencyProfiles = await repository.fetchCurrencyProfiles(clinicIds);

    // Fetch conversations
    updateProgress('Copilot Conversations');
    final conversations = await repository.fetchConversations(userId);

    // Fetch messages for each conversation
    updateProgress('Copilot Messages');
    final conversationsWithMessages = <Map<String, dynamic>>[];
    for (final conversation in conversations) {
      final messages = await repository.fetchMessages(conversation['id']);
      conversationsWithMessages.add({
        'conversation': conversation,
        'messages': messages,
      });
    }

    // Fetch doctors
    updateProgress('Doctors');
    final doctors = await repository.fetchDoctors(clinicIds);

    // Fetch staff
    updateProgress('Staff');
    final staff = await repository.fetchStaff(clinicIds);

    // Fetch invitations
    updateProgress('Invitations');
    final invitations = await repository.fetchInvitations(userEmail);

    // Fetch notifications
    updateProgress('Notifications');
    final notifications = await repository.fetchNotifications(userId);

    // Fetch ChatGPT projects
    updateProgress('ChatGPT Projects');
    final chatGPTProjects = await repository.fetchChatGPTProjects(userId);

    // Get app version
    updateProgress('Metadata');
    final packageInfo = await PackageInfo.fromPlatform();

    // Build the export data structure
    final exportData = {
      'exportMetadata': {
        'exportedAt': DateTime.now().toIso8601String(),
        'appVersion': packageInfo.version,
        'userId': userId,
        'userEmail': userEmail,
        'dataCategories': [
          'userProfile',
          'clinics',
          'patients',
          'clinicalReports',
          'sessions',
          'evaluations',
          'financials',
          'copilotConversations',
          'doctors',
          'staff',
          'invitations',
          'notifications',
          'chatGPTProjects',
        ],
      },
      'userProfile': userProfile,
      'clinics': clinics,
      'patients': patients,
      'clinicalReports': clinicalReports,
      'sessions': sessions,
      'evaluations': evaluations,
      'financials': {
        'invoices': invoices,
        'transactions': transactions,
        'bills': bills,
        'scheduledBills': scheduledBills,
        'goals': goals,
        'currencyProfiles': currencyProfiles,
      },
      'copilotConversations': conversationsWithMessages,
      'doctors': doctors,
      'staff': staff,
      'invitations': invitations,
      'notifications': notifications,
      'chatGPTProjects': chatGPTProjects,
    };

    updateProgress('Completed');
    return exportData;
  }

  /// Generates the export JSON file and saves it to the device.
  ///
  /// Returns the file path of the saved file.
  Future<String> _generateExportFile(
    Map<String, dynamic> data,
    String userId,
  ) async {
    try {
      // Convert to JSON with pretty printing
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create a filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'dr_copilot_export_${userId}_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      // Write the file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Get file size
      final fileSize = await file.length();
      debugPrint(
        '[ExportService] Export file created: $filePath (${_formatBytes(fileSize)})',
      );

      return filePath;
    } catch (e) {
      debugPrint('[ExportService] Error generating export file: $e');
      rethrow;
    }
  }

  /// Formats bytes into a human-readable string.
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Gets the file size in bytes for a given file path.
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      return await file.length();
    } catch (e) {
      debugPrint('[ExportService] Error getting file size: $e');
      return 0;
    }
  }

  /// Deletes the export file at the given path.
  Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[ExportService] Deleted export file: $filePath');
      }
    } catch (e) {
      debugPrint('[ExportService] Error deleting export file: $e');
    }
  }
}
