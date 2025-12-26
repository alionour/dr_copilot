import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

enum LimitType {
  sessions,
  evaluations,
  patients, // Total limit
  imageAnalysis,
  aiChat, // Daily limit
  aiTokens, // Monthly limit
}

class QuotaService {
  final FirebaseFirestore _firestore;

  QuotaService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String _getMonthKey() => DateFormat('yyyy_MM').format(DateTime.now());
  String _getDayKey() => DateFormat('yyyy_MM_dd').format(DateTime.now());

  /// Returns the document reference for clinic-wide monthly quotas
  DocumentReference _getClinicQuotaDoc(String clinicId) {
    return _firestore
        .collection('clinics')
        .doc(clinicId)
        .collection('usage_tracking')
        .doc(_getMonthKey());
  }

  /// Returns the document reference for user-specific daily quotas (like AI chat)
  DocumentReference _getUserQuotaDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('usage_tracking')
        .doc(_getDayKey());
  }

  /// Get current usage count for a specific limit type
  Future<int> getUsage(String clinicId, String? userId, LimitType type) async {
    try {
      if (type == LimitType.patients) {
        // Total limit - count documents in collection
        final count = await _firestore
            .collection('patients')
            .where('clinicId', isEqualTo: clinicId)
            .count()
            .get();
        return count.count ?? 0;
      }

      if (type == LimitType.aiChat) {
        if (userId == null) return 0;
        final doc = await _getUserQuotaDoc(userId).get();
        return (doc.data() as Map<String, dynamic>?)?['chat_count'] ?? 0;
      }

      // Monthly limits (Sessions, Evaluations, Image Analysis, AI Tokens)
      final doc = await _getClinicQuotaDoc(clinicId)
          .get(const GetOptions(source: Source.server));
      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) return 0;

      switch (type) {
        case LimitType.sessions:
          return data['session_count'] ?? 0;
        case LimitType.evaluations:
          return data['evaluation_count'] ?? 0;
        case LimitType.imageAnalysis:
          return data['image_analysis_count'] ?? 0;
        case LimitType.aiTokens:
          return data['token_count'] ?? 0;
        default:
          return 0;
      }
    } catch (e) {
      debugPrint('Error getting usage for $type: $e');
      return 0; // Fail open or closed? Open allows usage on error, closed blocks.
    }
  }

  /// Increment the usage counter for a specific type
  Future<void> incrementUsage(
    String clinicId,
    String? userId,
    LimitType type, {
    int amount = 1,
  }) async {
    try {
      if (type == LimitType.patients) {
        // No need to increment, we count documents directly
        return;
      }

      if (type == LimitType.aiChat) {
        if (userId == null) return;
        final docRef = _getUserQuotaDoc(userId);
        await docRef.set({
          'chat_count': FieldValue.increment(amount),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      // Monthly limits
      final docRef = _getClinicQuotaDoc(clinicId);
      final field = _getFieldForType(type);

      if (field != null) {
        await docRef.set({
          field: FieldValue.increment(amount),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error incrementing usage for $type: $e');
    }
  }

  String? _getFieldForType(LimitType type) {
    switch (type) {
      case LimitType.sessions:
        return 'session_count';
      case LimitType.evaluations:
        return 'evaluation_count';
      case LimitType.imageAnalysis:
        return 'image_analysis_count';
      case LimitType.aiTokens:
        return 'token_count';
      default:
        return null;
    }
  }
}
