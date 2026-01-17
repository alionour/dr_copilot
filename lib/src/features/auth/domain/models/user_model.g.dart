// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoURL: json['photoURL'] as String?,
      clinics: (json['clinics'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      primaryClinicId: json['primaryClinicId'] as String?,
      clinicIds: (json['clinicIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoURL': instance.photoURL,
      'clinics': instance.clinics,
      'primaryClinicId': instance.primaryClinicId,
      'clinicIds': instance.clinicIds,
    };
