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
  final String? ownerId;

  /// List of permissions as enums (AppPermission)
  /// A list of permissions assigned to the user, represented as [AppPermission] objects.
  /// This list determines the actions the user is authorized to perform within the application.
  @PermissionListJsonConverter()
  final List<AppPermission> permissions;

  /// List of roles as enums (AppRole)
  /// The list of roles assigned to the user, represented as [AppRole] objects.
  /// This determines the user's permissions and access levels within the application.
  @RoleListJsonConverter()
  final List<AppRole> roles;

  /// Multi-clinic support fields
  final List<String>? clinicIds;
  final String? primaryClinicId;

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
    this.clinicIds,
    this.primaryClinicId,
    this.ownerId,
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
    List<String>? clinicIds,
    String? primaryClinicId,
    String? ownerId,
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
      clinicIds: clinicIds ?? this.clinicIds,
      primaryClinicId: primaryClinicId ?? this.primaryClinicId,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user,
      {List<AppPermission>? permissions, List<AppRole>? roles}) {
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
      clinicIds: user.clinicIds,
      primaryClinicId: user.primaryClinicId,
      ownerId: user.ownerId,
    );
  }
}
