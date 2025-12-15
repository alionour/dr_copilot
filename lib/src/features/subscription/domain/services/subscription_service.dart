import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore;
  final QuotaService _quotaService;

  SubscriptionService({
    FirebaseFirestore? firestore,
    QuotaService? quotaService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _quotaService = quotaService ?? QuotaService();

  /// Fetches the current usage and checks against the limit.
  /// Returns [true] if the action is allowed.
  Future<bool> checkEntityLimit(String clinicId, LimitType type) async {
    final tier = await getCurrentTier(clinicId);
    int limit = -1;

    switch (type) {
      case LimitType.sessions:
        limit = tier.maxMonthlySessions;
        break;
      case LimitType.evaluations:
        limit = tier.maxMonthlyEvaluations;
        break;
      case LimitType.patients:
        limit = tier.maxPatients;
        break;
      case LimitType.imageAnalysis:
        limit = tier.monthlyImageAnalysisLimit;
        break;
      default:
        return true;
    }

    if (limit == -1) return true; // Unlimited

    final currentUsage = await _quotaService.getUsage(clinicId, null, type);
    return currentUsage < limit;
  }

  /// Checks if the user can chat with AI today.
  Future<bool> checkDailyChatLimit(String clinicId, String userId) async {
    final tier = await getCurrentTier(clinicId);
    if (tier.dailyChatLimit == -1) return true;

    final currentUsage = await _quotaService.getUsage(
      clinicId,
      userId,
      LimitType.aiChat,
    );
    return currentUsage < tier.dailyChatLimit;
  }

  /// Get the current tier for a clinic.
  /// Defaults to Free if not found or error.
  Future<SubscriptionTier> getCurrentTier(String clinicId) async {
    try {
      final doc = await _firestore.collection('clinics').doc(clinicId).get();
      if (!doc.exists) return SubscriptionTier.free;

      final data = doc.data();
      final tierStr = data?['subscriptionTier'] as String?;
      return SubscriptionTier.fromString(tierStr);
    } catch (e) {
      debugPrint('Error fetching subscription tier: $e');
      return SubscriptionTier.free;
    }
  }

  /// Check if a specific feature is allowed by the plan.
  /// This doesn't check quotas, just the static plan capability.
  Future<bool> isFeatureAllowed(
    String clinicId,
    SubscriptionFeature feature,
  ) async {
    final tier = await getCurrentTier(clinicId);
    switch (feature) {
      case SubscriptionFeature.exportData:
        return tier.canExportData;
      case SubscriptionFeature.cloudBackup:
        return tier.canUseCloudBackup;
      case SubscriptionFeature.deepgram:
        return tier.canUseDeepgram;
      case SubscriptionFeature.advancedAI:
        return tier.canUseAdvancedModels;
      case SubscriptionFeature.inviteMembers:
        return tier.canInviteMembers;
      case SubscriptionFeature.eliteAI:
        return tier.canUseEliteModels;
    }
  }

  // Method to check Team Limits (Doctors/Staff)
  // Used before sending an invitation
  Future<bool> canInviteRole(String clinicId, String role) async {
    final tier = await getCurrentTier(clinicId);

    // Quick check: if invites disabled entirely
    if (!tier.canInviteMembers) return false;

    int limit = -1;

    if (role.toLowerCase() == 'doctor') {
      limit = tier.maxDoctors;
    } else if (role.toLowerCase() == 'staff') {
      limit = tier.maxStaff;
    } else {
      return true; // Other roles? Assuming allowed or handled elsewhere
    }

    if (limit == -1) return true;

    // Count current members
    // NOTE: This assumes there is a subcollection or a query we can run.
    // Based on `CreateInvitationPage`, it uses `StaffUseCases` which likely queries `users` or a subcollection.
    // We will query the Invites + Active Members to be safe, but for now let's query the `users` collection
    // filtering by clinicId and role if possible, or assume there's a strict collection structure.

    // Strategy: Query 'users' collection where clinicId == id AND role == role
    // This requires an index.
    // Alternative: The `CreateInvitationPage` logic relies on `getAllStaff` usecase.
    // For this service, let's try direct count if possible, or assume caller passes current count (refactor later).

    // Let's implement a direct count query.
    try {
      // We might need to adjust this query based on actual DB structure.
      // Assuming 'users' has 'clinicId' and 'role'.
      // If strict subcollections exist (clinics/{id}/staff), use that.
      // `CreateInvitationPage` calls `sl<StaffUseCases>().getAllStaff`.
      // Let's stick to a robust query if we can.

      // Optimization: If limit is small (1, 3, 5), reading all isn't too expensive.
      final snapshot = await _firestore
          .collection('users')
          .where('primaryClinicId', isEqualTo: clinicId)
          .where('role', isEqualTo: role)
          .count()
          .get();

      final currentCount = snapshot.count ?? 0;

      // Also count pending invitations?
      final pendingInvites = await _firestore
          .collection('invitations')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'pending')
          .where('roles', arrayContains: role)
          .count()
          .get();

      final totalCount = currentCount + (pendingInvites.count ?? 0);

      return totalCount < limit;
    } catch (e) {
      debugPrint('Error counting team members: $e');
      return false; // Fail safe
    }
  }
}

enum SubscriptionFeature {
  exportData,
  cloudBackup,
  deepgram,
  advancedAI,
  inviteMembers,
  eliteAI,
}

