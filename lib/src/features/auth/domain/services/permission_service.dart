import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_permissions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for checking user permissions based on their assigned roles.
///
/// This service integrates with Firebase Auth and Firestore to determine
/// if a user has specific permissions within a clinic context.
class PermissionService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  PermissionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Checks if the current user has a specific permission.
  ///
  /// [permission] - The permission string to check (e.g., 'can_add_patient')
  /// [clinicId] - Optional clinic ID to check clinic-specific roles
  ///
  /// Returns true if user has the permission, false otherwise.
  /// Fails closed (returns false) on errors.
  Future<bool> hasPermission(String permission, {String? clinicId}) async {
    final permissions = await getUserPermissions(clinicId: clinicId);
    return permissions?.contains(permission) ?? false;
  }

  /// Checks if user has ALL of the specified permissions.
  ///
  /// [permissions] - List of permission strings to check
  /// [clinicId] - Optional clinic ID for context
  ///
  /// Returns true only if user has ALL permissions.
  Future<bool> hasAllPermissions(List<String> permissions,
      {String? clinicId}) async {
    final userPerms = await getUserPermissions(clinicId: clinicId);
    if (userPerms == null) return false;

    for (final permission in permissions) {
      if (!userPerms.contains(permission)) {
        return false;
      }
    }
    return true;
  }

  /// Checks if user has ANY of the specified permissions.
  ///
  /// [permissions] - List of permission strings to check
  /// [clinicId] - Optional clinic ID for context
  ///
  /// Returns true if user has at least one permission.
  Future<bool> hasAnyPermission(List<String> permissions,
      {String? clinicId}) async {
    final userPerms = await getUserPermissions(clinicId: clinicId);
    if (userPerms == null) return false;

    for (final permission in permissions) {
      if (userPerms.contains(permission)) {
        return true;
      }
    }
    return false;
  }

  /// Gets all permissions for the current user.
  ///
  /// [clinicId] - Optional clinic ID for context
  ///
  /// Returns a list of all permission strings the user has.
  /// Returns null on error.
  Future<List<String>?> getUserPermissions({String? clinicId}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      // 1. Check if user is the OWNER of the clinic
      if (clinicId != null) {
        debugPrint(
            '[PermissionService] Checking owner for clinicId: $clinicId, userId: $userId');
        final clinicDoc =
            await _firestore.collection('clinics').doc(clinicId).get();
        if (clinicDoc.exists) {
          final ownerId = clinicDoc.data()?['ownerId'];
          debugPrint('[PermissionService] Clinic ownerId: $ownerId');
          if (ownerId == userId) {
            debugPrint(
                '[PermissionService] User is OWNER - granting all permissions');
            // Owners get ALL permissions implicitly
            return [
              'can_add_patient',
              'can_edit_patient',
              'can_delete_patient',
              'can_view_patient',
              'can_add_session',
              'can_edit_session',
              'can_delete_session',
              'can_view_session',
              'can_add_evaluation',
              'can_edit_evaluation',
              'can_delete_evaluation',
              'can_view_evaluation',
              'can_view_analytics',
              'can_manage_clinic',
              'can_manage_staff',
              'can_assign_roles',
              'can_view_financials',
              'can_use_copilot'
            ];
          }
        } else {
          debugPrint(
              '[PermissionService] Clinic doc does not exist for $clinicId');
        }
      } else {
        debugPrint(
            '[PermissionService] clinicId is NULL - skipping owner check');
      }

      // 2. Initial role set & direct permissions
      List<String> userRoles = [];
      Set<String> allPermissions = {};

      // 3. Try to get roles and permissions from clinic members subcollection
      if (clinicId != null) {
        final memberDoc = await _firestore
            .collection('clinics')
            .doc(clinicId)
            .collection('members')
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          final memberData = memberDoc.data();
          debugPrint('[PermissionService] Found member doc: $memberData');

          if (memberData != null) {
            // Handle Roles
            if (memberData['role'] != null) {
              if (memberData['role'] is String) {
                userRoles.add(memberData['role'] as String);
              } else if (memberData['role'] is List) {
                userRoles.addAll(List<String>.from(memberData['role']));
              }
            }
            if (memberData['roles'] != null && memberData['roles'] is List) {
              userRoles.addAll(List<String>.from(memberData['roles']));
            }

            // Handle Direct Permissions
            if (memberData['permissions'] != null) {
              debugPrint('[PermissionService] Found direct permissions list');
              if (memberData['permissions'] is List) {
                allPermissions
                    .addAll(List<String>.from(memberData['permissions']));
              }
            }
          }
        }
      }

      // 4. Fallback: Check user document for global roles (legacy/backup)
      if (userRoles.isEmpty && allPermissions.isEmpty) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        if (userData != null && userData['roles'] != null) {
          try {
            userRoles = List<String>.from(userData['roles'] as List);
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }

      debugPrint('[PermissionService] Final user roles: $userRoles');

      // 5. Add Key-Based Permissions from Roles
      for (final role in userRoles) {
        final permissions = rolePermissions[role] ?? [];
        allPermissions.addAll(permissions);
      }

      return allPermissions.toList();
    } catch (e) {
      debugPrint('[PermissionService] Error getting user permissions: $e');
      return null;
    }
  }
}
