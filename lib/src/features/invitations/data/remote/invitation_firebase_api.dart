import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class InvitationFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createInvitation(InvitationModel invitation) async {
    if (!OwnerNotifier().hasPermission(AppPermission.sendInvitation)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore
          .collection('user_invitations')
          .doc(invitation.id)
          .set(invitation.toJson());
    } catch (e) {
      log('Error creating invitation: $e');
      throw ServerException(e.toString(), 500);
    }
  }

  Future<List<InvitationModel>> getInvitationsByClinic(String clinicId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.viewInvitations)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      final snapshot = await _firestore
          .collection('user_invitations')
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvitationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      // Log the full error to get the index creation link
      log('========================================');
      log('FIRESTORE INDEX ERROR:');
      log(e.toString());
      log('========================================');
      throw ServerException(e.toString(), 500);
    }
  }

  Future<List<InvitationModel>> getPendingInvitationsByClinic(
    String clinicId,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.viewInvitations)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      final snapshot = await _firestore
          .collection('user_invitations')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvitationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      // Log the full error to get the index creation link
      log('========================================');
      log('FIRESTORE INDEX ERROR:');
      log(e.toString());
      log('========================================');
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> deleteInvitation(String invitationId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.revokeInvitation)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .delete();
    } catch (e) {
      log('Error deleting invitation: $e');
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> resendInvitation(String invitationId) async {
    if (!OwnerNotifier().hasPermission(AppPermission.sendInvitation)) {
      throw ServerException('Permission denied', 403);
    }
    try {
      await _firestore.collection('user_invitations').doc(invitationId).update({
        'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      });
    } catch (e) {
      log('Error resending invitation: $e');
    }
  }

  Future<List<InvitationModel>> getInvitationsForEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection('user_invitations')
          .where('email', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => InvitationModel.fromDocument(doc))
          .toList();
    } catch (e) {
      log('Error fetching invitations for email: $e');
      throw ServerException(e.toString(), 500);
    }
  }

  Future<void> rejectInvitation(String invitationId, String email) async {
    try {
      // 1. Fetch the invitation to verify eligibility
      final docSnapshot = await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .get();

      if (!docSnapshot.exists) {
        throw ServerException('Invitation not found', 404);
      }

      final data = docSnapshot.data();
      if (data == null || data['email'] != email) {
        // Security check: Only the invitee can reject it
        throw ServerException('Permission denied: Email mismatch', 403);
      }

      // 2. Delete the invitation
      await _firestore
          .collection('user_invitations')
          .doc(invitationId)
          .delete();
    } catch (e) {
      log('Error rejecting invitation: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString(), 500);
    }
  }
}
