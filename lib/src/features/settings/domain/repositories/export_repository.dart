import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Repository responsible for fetching user data from Firestore for export purposes.
///
/// This repository aggregates data from multiple Firestore collections and
/// provides methods to fetch each category of user data.
class ExportRepository {
  final FirebaseFirestore _firestore;

  ExportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetches the user profile data from Firestore.
  ///
  /// Returns a map containing user profile fields (uid, email, displayName, etc.)
  /// or null if the user document doesn't exist.
  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // Return only the fields stored in Firestore (exclude runtime Firebase Auth fields)
      return {
        'uid': data['uid'],
        'email': data['email'],
        'displayName': data['displayName'],
        'photoURL': data['photoURL'],
        'clinics': data['clinics'],
        'primaryClinicId': data['primaryClinicId'],
        'clinicIds': data['clinicIds'],
      };
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching user profile: $e');
      rethrow;
    }
  }

  /// Fetches all clinic information for the given clinic IDs.
  Future<List<Map<String, dynamic>>> fetchClinics(
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      // Firestore 'in' queries are limited to 10 items, so we batch them
      for (var i = 0; i < clinicIds.length; i += 10) {
        final batch = clinicIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('clinics')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching clinics: $e');
      rethrow;
    }
  }

  /// Fetches all patients owned by the user in the specified clinics.
  Future<List<Map<String, dynamic>>> fetchPatients(
    String userId,
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (final clinicId in clinicIds) {
        final querySnapshot = await _firestore
            .collection('patients')
            .where('ownerId', isEqualTo: userId)
            .where('clinicId', isEqualTo: clinicId)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching patients: $e');
      rethrow;
    }
  }

  /// Fetches all clinical reports for the given patient IDs.
  Future<List<Map<String, dynamic>>> fetchClinicalReports(
    List<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      // Batch queries in groups of 10 due to Firestore 'in' limitation
      for (var i = 0; i < patientIds.length; i += 10) {
        final batch = patientIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('clinicalReports')
            .where('patientId', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching clinical reports: $e');
      rethrow;
    }
  }

  /// Fetches all sessions owned by the user in the specified clinics.
  Future<List<Map<String, dynamic>>> fetchSessions(
    String userId,
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (final clinicId in clinicIds) {
        final querySnapshot = await _firestore
            .collection('sessions')
            .where('ownerId', isEqualTo: userId)
            .where('clinicId', isEqualTo: clinicId)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching sessions: $e');
      rethrow;
    }
  }

  /// Fetches all evaluations for the given patient IDs.
  Future<List<Map<String, dynamic>>> fetchEvaluations(
    List<String> patientIds,
  ) async {
    if (patientIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < patientIds.length; i += 10) {
        final batch = patientIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('evaluations')
            .where('patientId', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching evaluations: $e');
      rethrow;
    }
  }

  /// Fetches all invoices owned by the user in the specified clinics.
  Future<List<Map<String, dynamic>>> fetchInvoices(
    String userId,
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (final clinicId in clinicIds) {
        final querySnapshot = await _firestore
            .collection('invoices')
            .where('ownerId', isEqualTo: userId)
            .where('clinicId', isEqualTo: clinicId)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching invoices: $e');
      rethrow;
    }
  }

  /// Fetches all transactions for the given invoice IDs.
  Future<List<Map<String, dynamic>>> fetchTransactions(
    List<String> invoiceIds,
  ) async {
    if (invoiceIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < invoiceIds.length; i += 10) {
        final batch = invoiceIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('transactions')
            .where('invoiceId', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching transactions: $e');
      rethrow;
    }
  }

  /// Fetches all bills owned by the user.
  Future<List<Map<String, dynamic>>> fetchBills(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bills')
          .where('ownerId', isEqualTo: userId)
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching bills: $e');
      rethrow;
    }
  }

  /// Fetches all scheduled bills owned by the user.
  Future<List<Map<String, dynamic>>> fetchScheduledBills(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('scheduledBills')
          .where('ownerId', isEqualTo: userId)
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching scheduled bills: $e');
      rethrow;
    }
  }

  /// Fetches all financial goals owned by the user.
  Future<List<Map<String, dynamic>>> fetchGoals(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('goals')
          .where('ownerId', isEqualTo: userId)
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching goals: $e');
      rethrow;
    }
  }

  /// Fetches all currency profiles for the user's clinics.
  Future<List<Map<String, dynamic>>> fetchCurrencyProfiles(
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < clinicIds.length; i += 10) {
        final batch = clinicIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('currencyProfiles')
            .where('clinicId', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching currency profiles: $e');
      rethrow;
    }
  }

  /// Fetches all copilot conversations for the user.
  Future<List<Map<String, dynamic>>> fetchConversations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Fetches all messages for a given conversation.
  Future<List<Map<String, dynamic>>> fetchMessages(
    String conversationId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching messages: $e');
      rethrow;
    }
  }

  /// Fetches all doctors in the user's clinics.
  Future<List<Map<String, dynamic>>> fetchDoctors(
    List<String> clinicIds,
  ) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < clinicIds.length; i += 10) {
        final batch = clinicIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('doctors')
            .where('clinicId', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching doctors: $e');
      rethrow;
    }
  }

  /// Fetches all staff members in the user's clinics.
  Future<List<Map<String, dynamic>>> fetchStaff(List<String> clinicIds) async {
    if (clinicIds.isEmpty) return [];

    try {
      final results = <Map<String, dynamic>>[];

      for (var i = 0; i < clinicIds.length; i += 10) {
        final batch = clinicIds.skip(i).take(10).toList();
        final querySnapshot = await _firestore
            .collection('staff')
            .where('clinicId', whereIn: batch)
            .get();

        for (var doc in querySnapshot.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching staff: $e');
      rethrow;
    }
  }

  /// Fetches all invitations sent by or received by the user.
  Future<List<Map<String, dynamic>>> fetchInvitations(String userEmail) async {
    try {
      final results = <Map<String, dynamic>>[];

      // Fetch invitations sent by the user
      final sentSnapshot = await _firestore
          .collection('invitations')
          .where('senderEmail', isEqualTo: userEmail)
          .get();

      for (var doc in sentSnapshot.docs) {
        results.add({'id': doc.id, 'direction': 'sent', ...doc.data()});
      }

      // Fetch invitations received by the user
      final receivedSnapshot = await _firestore
          .collection('invitations')
          .where('recipientEmail', isEqualTo: userEmail)
          .get();

      for (var doc in receivedSnapshot.docs) {
        results.add({'id': doc.id, 'direction': 'received', ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching invitations: $e');
      rethrow;
    }
  }

  /// Fetches notifications for the user (limited to last 20 as per app design).
  Future<List<Map<String, dynamic>>> fetchNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Fetches all ChatGPT projects owned by the user.
  Future<List<Map<String, dynamic>>> fetchChatGPTProjects(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('chatgptProjects')
          .where('userId', isEqualTo: userId)
          .get();

      final results = <Map<String, dynamic>>[];
      for (var doc in querySnapshot.docs) {
        results.add({'id': doc.id, ...doc.data()});
      }

      return results;
    } catch (e) {
      debugPrint('[ExportRepository] Error fetching ChatGPT projects: $e');
      rethrow;
    }
  }
}

