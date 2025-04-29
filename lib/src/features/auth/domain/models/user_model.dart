import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()

/// Represents a user in the authentication domain.
///
/// Contains basic user information such as [uid], [name], [email], and an optional [profilePicture].
///
/// Provides methods for serializing to and from JSON.
///
/// Contains user-related information and properties used throughout the application.
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
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
  }) {
    return UserModel(
      uid: id ?? this.uid,
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
    );
  }

  factory UserModel.fromFirebaseUser(dynamic user) {
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
    );
  }
}
