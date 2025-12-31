import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' show UserMetadata;

part 'user_model.g.dart';

/// Represents a user in the authentication domain.
///
/// Contains essential user information from Firestore and Firebase Auth.
///
/// Firestore fields: uid, email, displayName, photoURL, clinics, primaryClinicId
/// Runtime fields from Firebase Auth: emailVerified, isAnonymous, metadata, phoneNumber, providerData, refreshToken, tenantId
@JsonSerializable()
class UserModel {
  // === Firestore fields (stored in database) ===

  /// The unique identifier for the user (from Firebase Auth).
  final String uid;

  /// The user's email address.
  final String? email;

  /// The user's display name.
  final String? displayName;

  /// The URL of the user's profile photo.
  final String? photoURL;

  /// Multi-clinic support - array of clinic memberships with roles
  final List<Map<String, dynamic>>? clinics;

  /// User's primary/default clinic
  final String? primaryClinicId;

  /// Legacy field for backward compatibility - derived from clinics array
  final List<String>? clinicIds;

  // === Runtime fields from Firebase Auth (not stored in Firestore) ===
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? emailVerified;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool? isAnonymous;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final UserMetadata? metadata;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? phoneNumber;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final List<dynamic>? providerData;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? refreshToken;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? tenantId;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.clinics,
    this.primaryClinicId,
    this.clinicIds,
    // Runtime fields from Firebase Auth
    this.emailVerified,
    this.isAnonymous,
    this.metadata,
    this.phoneNumber,
    this.providerData,
    this.refreshToken,
    this.tenantId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    List<Map<String, dynamic>>? clinics,
    String? primaryClinicId,
    List<String>? clinicIds,
    bool? emailVerified,
    bool? isAnonymous,
    UserMetadata? metadata,
    String? phoneNumber,
    List<dynamic>? providerData,
    String? refreshToken,
    String? tenantId,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      clinics: clinics ?? this.clinics,
      primaryClinicId: primaryClinicId ?? this.primaryClinicId,
      clinicIds: clinicIds ?? this.clinicIds,
      emailVerified: emailVerified ?? this.emailVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      metadata: metadata ?? this.metadata,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      providerData: providerData ?? this.providerData,
      refreshToken: refreshToken ?? this.refreshToken,
      tenantId: tenantId ?? this.tenantId,
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      metadata: user.metadata,
      phoneNumber: user.phoneNumber,
      providerData: user.providerData,
      refreshToken: user.refreshToken,
      tenantId: user.tenantId,
    );
  }

  // Helper methods for clinic-based roles

  /// Gets the user's role in a specific clinic.
  ///
  /// First checks the [clinics] array (new structure), then falls back to
  /// checking the `clinics/{clinicId}/members/{uid}` document in Firestore
  /// (migration fallback).
  Future<String?> getRoleInClinic(String clinicId) async {
    // First, try to get role from clinics array (new multi-clinic structure)
    if (clinics != null) {
      try {
        final clinic = clinics!.firstWhere(
          (c) => c['clinicId'] == clinicId,
          orElse: () => {},
        );
        final role = clinic['role'] as String?;
        if (role != null) return role;
      } catch (e) {
        debugPrint('[UserModel] Error reading from clinics array: $e');
      }
    }

    // Fallback: Query Firestore for role in clinic members subcollection
    // This handles cases where the user hasn't been migrated to the new structure
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final memberDoc = await firestore
          .collection('clinics')
          .doc(clinicId)
          .collection('members')
          .doc(uid)
          .get();

      if (memberDoc.exists) {
        final role = memberDoc.data()?['role'] as String?;
        debugPrint(
          '[UserModel] Fetched role from Firestore for clinic $clinicId: $role',
        );
        return role;
      }
    } catch (e) {
      debugPrint('[UserModel] Error fetching role from Firestore: $e');
    }

    debugPrint('[UserModel] No role found for user $uid in clinic $clinicId');
    return null;
  }

  /// Checks if the user is an admin in a specific clinic.
  Future<bool> isAdminInClinic(String clinicId) async {
    final role = await getRoleInClinic(clinicId);
    return role?.toLowerCase() == 'admin';
  }

  /// Checks if the user belongs to a specific clinic.
  bool belongsToClinic(String clinicId) {
    return clinicIds?.contains(clinicId) ?? false;
  }

  /// Gets all clinic IDs where the user has the 'admin' role.
  List<String> get adminClinicIds {
    if (clinics == null) return [];
    return clinics!
        .where((c) => (c['role'] as String?)?.toLowerCase() == 'admin')
        .map((c) => c['clinicId'] as String)
        .toList();
  }
}
