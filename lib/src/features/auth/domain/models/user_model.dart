import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

/// Represents a user in the authentication domain.
///
/// Contains basic user information such as [uid], [displayName], [email], and an optional [profilePicture].
///
/// Provides methods for serializing to and from JSON.
///
/// Contains user-related information and properties used throughout the application.
@JsonSerializable()
class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final bool? emailVerified;
  final bool? isAnonymous;
  final dynamic metadata;
  final String? phoneNumber;
  final String? photoURL;
  final List<dynamic>? providerData;
  final String? refreshToken;
  final String? tenantId;

  /// List of permission strings (e.g., 'can_edit_patient', 'can_view_financials')
  final List<AppPermission> permissions;

  /// List of role group names (e.g., 'admin', 'doctor', 'staff')
  final List<AppRole> roles;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    this.emailVerified,
    this.isAnonymous,
    this.metadata,
    this.phoneNumber,
    this.photoURL,
    this.providerData,
    this.refreshToken,
    this.tenantId,
    this.permissions = const [],
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    bool? emailVerified,
    bool? isAnonymous,
    dynamic metadata,
    String? phoneNumber,
    String? photoURL,
    List<dynamic>? providerData,
    String? refreshToken,
    String? tenantId,
    List<AppPermission>? permissions,
    List<AppRole>? roles,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      metadata: metadata ?? this.metadata,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      providerData: providerData ?? this.providerData,
      refreshToken: refreshToken ?? this.refreshToken,
      tenantId: tenantId ?? this.tenantId,
      permissions: permissions ?? this.permissions,
      roles: roles ?? this.roles,
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user, {List<AppPermission>? permissions, List<AppRole>? roles}) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      emailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      metadata: user.metadata,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      providerData: user.providerData,
      refreshToken: user.refreshToken,
      tenantId: user.tenantId,
      permissions: permissions ?? const [],
      roles: roles ?? const [],
    );
  }
}
