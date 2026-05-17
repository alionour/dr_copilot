import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

/// Service for checking user permissions based on their assigned roles.
///
/// This service integrates with Firebase Auth and Firestore to determine
/// if a user has specific permissions within a clinic context.
class PermissionService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Permission cache: clinicId -> list of permission names
  final Map<String, List<String>> _permissionCache = {};
  DateTime? _cacheExpiry;
  bool _isRefreshing = false;
  static const _cacheDuration = Duration(minutes: 5);

  PermissionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Synchronous permission check using cached permissions.
  ///
  /// This is the preferred method for UI permission checks.
  /// Returns false if permissions are not cached yet.
  ///
  /// [permission] - The AppPermission enum to check
  /// [clinicId] - Optional clinic ID, falls back to user's primary clinic
  bool hasPermissionSync(AppPermission permission, {String? clinicId}) {
    final cached = _getCachedPermissions(clinicId);
    final hasIt = cached?.contains(permission.name) ?? false;

    if (!hasIt && cached != null) {
      debugPrint(
          '[PermissionService] Permission check FAILED: ${permission.name} not in cached permissions');
      debugPrint('[PermissionService] User has: $cached');
    }

    return hasIt;
  }

  /// Get cached permissions for a clinic.
  /// returns cached permissions if they exist, even if expired (stale-while-revalidate)
  List<String>? _getCachedPermissions(String? clinicId) {
    // Check if cache is expired
    if (_cacheExpiry != null && DateTime.now().isAfter(_cacheExpiry!)) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        debugPrint(
            '[PermissionService] Cache expired. Returning stale data and refreshing in background...');
        // Trigger background refresh
        // We don't await this because we want to return the stale data immediately
        getUserPermissions(clinicId: clinicId, forceRefresh: true)
            .whenComplete(() {
          _isRefreshing = false;
          // If the refresh failed to update _cacheExpiry (still expired),
          // bump it slightly to prevent immediate retry loop.
          if (_cacheExpiry != null && DateTime.now().isAfter(_cacheExpiry!)) {
            debugPrint(
                '[PermissionService] Bumping cache expiry by 10s to prevent retry loop.');
            _cacheExpiry = DateTime.now().add(const Duration(seconds: 10));
          }
        }).ignore();
      }

      // Do NOT clear the cache here.
      // We return the stale data below so the UI doesn't break.
      // _cacheExpiry will be updated when the background refresh completes.
    }

    final key = clinicId ?? 'default';
    return _permissionCache[key];
  }

  /// Set cached permissions for a clinic.
  void _setCachedPermissions(String? clinicId, List<String> permissions) {
    final key = clinicId ?? 'default';
    _permissionCache[key] = permissions;
    _cacheExpiry = DateTime.now().add(_cacheDuration);
    debugPrint(
        '[PermissionService] Cached ${permissions.length} permissions for clinic $key');
  }

  /// Clear the permission cache.
  /// Call this on logout or when permissions change.
  void clearCache() {
    debugPrint('[PermissionService] Clearing permission cache');
    _permissionCache.clear();
    _cacheExpiry = null;
    _isRefreshing = false;
  }

  /// Checks if the current user has a specific permission (async).
  ///
  /// [permission] - The permission string to check (e.g., 'viewAllPatients')
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
  /// [forceRefresh] - If true, ignores cache and fetches from Firestore.
  ///
  /// Returns a list of all permission strings the user has.
  /// Returns null on error.
  /// Automatically caches results for better performance.
  Future<List<String>?> getUserPermissions(
      {String? clinicId, bool forceRefresh = false}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      if (!forceRefresh) {
        // Check cache first
        final cached = _getCachedPermissions(clinicId);
        if (cached != null) {
          debugPrint(
              '[PermissionService] Returning ${cached.length} cached permissions');
          return cached;
        }
      }

      // If no clinicId provided, try to get from user's primary clinic
      String? targetClinicId = clinicId;
      if (targetClinicId == null) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        targetClinicId = userDoc.data()?['primaryClinicId'];
      }

      if (targetClinicId == null) {
        debugPrint(
            '[PermissionService] No clinicId available - cannot load permissions');
        return null;
      }

      debugPrint(
          '[PermissionService] Loading permissions from Firestore for userId: $userId, clinicId: $targetClinicId');

      // Get permissions directly from clinic members subcollection
      final memberDoc = await _firestore
          .collection('clinics')
          .doc(targetClinicId)
          .collection('members')
          .doc(userId)
          .get();

      List<String> permissions = [];
      if (memberDoc.exists && memberDoc.data() != null) {
        final memberData = memberDoc.data()!;
        if (memberData['permissions'] is List) {
          permissions = List<String>.from(memberData['permissions']);
        }
      }

      debugPrint(
          '[PermissionService] Loaded ${permissions.length} permissions');

      // Cache the permissions
      _setCachedPermissions(targetClinicId, permissions);

      return permissions;
    } catch (e) {
      debugPrint('[PermissionService] Error getting user permissions: $e');
      return null;
    }
  }
}
