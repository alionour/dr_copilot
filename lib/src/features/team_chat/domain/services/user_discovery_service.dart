import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

class UserDiscoveryService {
  final FirebaseFirestore _firestore;

  UserDiscoveryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch all users who are in the same teams as the current user
  ///
  /// Returns users who share at least one team with the current user.
  /// If the user is not in any teams, returns an empty list.
  Future<List<UserModel>> getClinicMembers(
    String clinicId,
    String currentUserId,
  ) async {
    try {
      // Get all teams where current user is a member
      final teamsSnapshot = await _firestore
          .collection('custom_teams')
          .where('clinicId', isEqualTo: clinicId)
          .where('memberIds', arrayContains: currentUserId)
          .get();

      if (teamsSnapshot.docs.isEmpty) {
        // User is not in any teams
        return [];
      }

      // Collect all unique member IDs from these teams
      final Set<String> teammateIds = {};
      for (var teamDoc in teamsSnapshot.docs) {
        final memberIds = List<String>.from(teamDoc.data()['memberIds'] ?? []);
        teammateIds.addAll(memberIds);
      }

      // Remove current user from the list
      teammateIds.remove(currentUserId);

      if (teammateIds.isEmpty) {
        return [];
      }

      // Fetch user data for all teammates
      final List<UserModel> users = [];
      for (var userId in teammateIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists && userDoc.data() != null) {
          try {
            // Add uid to the data since it's not stored as a field
            final userData = userDoc.data()!;
            userData['uid'] = userId;
            users.add(UserModel.fromJson(userData));
          } catch (e) {
            // Skip invalid user data
          }
        }
      }

      return users;
    } catch (e) {
      return [];
    }
  }
}

