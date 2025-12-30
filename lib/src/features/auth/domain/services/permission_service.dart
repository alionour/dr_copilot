import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

/// Service for checking user permissions based on their assigned roles.
///
/// This service integrates with Firebase Auth and Firestore to determine
/// if a user has specific permissions within a clinic context.
class PermissionService {
  final FirebaseFirestore _firestore;

  // Real-time permission state
  final Map<String, List<String>> _permissionCache = {};
  StreamSubscription<DocumentSnapshot>? _permissionSubscription;

  PermissionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Alias for dispose/clearing cache
  Future<void> clearCache() => dispose();

  /// Synchronous permission check using the latest streamed data.
  bool hasPermissionSync(AppPermission permission, {String? clinicId}) {
    final key = clinicId ?? 'default';
    final permissions = _permissionCache[key];

    // If we have no data yet, return false (fail closed)
    if (permissions == null) {
      debugPrint('[PermissionService] Check failed: No data for clinic $key');
      return false;
    }

    return permissions.contains(permission.name);
  }

  /// Initialize real-time listener for permissions.
  /// Call this on login or app start.
  Future<void> initialize(String userId, {String? clinicId}) async {
    // Cancel existing subscription if any
    await dispose();

    String? targetClinicId = clinicId;

    // If no clinicId provided, try to get from user's primary clinic
    if (targetClinicId == null) {
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        targetClinicId = userDoc.data()?['primaryClinicId'];
      } catch (e) {
        debugPrint('[PermissionService] Failed to fetch primaryClinicId: $e');
      }
    }

    if (targetClinicId == null) {
      debugPrint('[PermissionService] No clinicId found. Cannot subscribe.');
      return;
    }

    debugPrint(
        '[PermissionService] Subscribing to permissions for user $userId in clinic $targetClinicId');

    _permissionSubscription = _firestore
        .collection('clinics')
        .doc(targetClinicId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['permissions'] is List) {
          final permissions = List<String>.from(data['permissions']);
          _permissionCache[targetClinicId!] = permissions;
          _permissionCache['default'] = permissions; // Set default alias

          debugPrint(
              '[PermissionService] Updated permissions (Count: ${permissions.length})');
        } else {
          debugPrint(
              '[PermissionService] Document valid but no permissions list found.');
          _permissionCache.clear();
        }
      } else {
        debugPrint(
            '[PermissionService] Member document does not exist (removed given permissions?)');
        _permissionCache.clear();
      }
    }, onError: (error) {
      debugPrint('[PermissionService] Stream error: $error');
    });
  }

  /// Stop listening directly.
  Future<void> dispose() async {
    await _permissionSubscription?.cancel();
    _permissionSubscription = null;
    _permissionCache.clear();
    debugPrint('[PermissionService] Disposed listener.');
  }

  // Legacy async method support (optional, can just wrap sync)
  Future<bool> hasPermission(String permission, {String? clinicId}) async {
    // If subscription is active, use sync check
    if (_permissionSubscription != null) {
      // We need to map string to enum if we want to use hasPermissionSync properly,
      // OR just check the string list directly.
      final key = clinicId ?? 'default';
      return _permissionCache[key]?.contains(permission) ?? false;
    }

    // Fallback for one-off checks if not initialized (though initialize is preferred)
    // For now, we assume initialized.
    return false;
  }

  Future<List<String>?> getUserPermissions({String? clinicId}) async {
    // Return current cached state
    final key = clinicId ?? 'default';
    return _permissionCache[key];
  }
}
