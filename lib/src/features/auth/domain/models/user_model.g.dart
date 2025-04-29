// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: json['id'] as String,
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
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.uid,
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
    };
