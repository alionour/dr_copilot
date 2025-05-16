// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      emailVerified: json['emailVerified'] as bool?,
      isAnonymous: json['isAnonymous'] as bool?,
      metadata: json['metadata'],
      phoneNumber: json['phoneNumber'] as String?,
      photoURL: json['photoURL'] as String?,
      providerData: json['providerData'] as List<dynamic>?,
      refreshToken: json['refreshToken'] as String?,
      tenantId: json['tenantId'] as String?,
      permissions: json['permissions'] == null
          ? const []
          : const PermissionListJsonConverter()
              .fromJson(json['permissions'] as List<String>),
      roles: json['roles'] == null
          ? const []
          : const RoleListJsonConverter().fromJson(json['roles'] as List),
      clinicIds: (json['clinicIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      primaryClinicId: json['primaryClinicId'] as String?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.uid,
      'displayName': instance.displayName,
      'email': instance.email,
      'emailVerified': instance.emailVerified,
      'isAnonymous': instance.isAnonymous,
      'metadata': instance.metadata,
      'phoneNumber': instance.phoneNumber,
      'photoURL': instance.photoURL,
      'providerData': instance.providerData,
      'refreshToken': instance.refreshToken,
      'tenantId': instance.tenantId,
      'permissions':
          const PermissionListJsonConverter().toJson(instance.permissions),
      'roles': const RoleListJsonConverter().toJson(instance.roles),
      'clinicIds': instance.clinicIds,
      'primaryClinicId': instance.primaryClinicId,
    };
