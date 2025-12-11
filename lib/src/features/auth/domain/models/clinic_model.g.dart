// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clinic_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClinicModel _$ClinicModelFromJson(Map<String, dynamic> json) => ClinicModel(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String?,
  ownerId: json['ownerId'] as String,
  adminEmail: json['adminEmail'] as String,
  createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
  subscriptionTier: json['subscriptionTier'] as String?,
  isSubscriptionActive: json['isSubscriptionActive'] as bool?,
  subscriptionUpdatedAt: const NullableTimestampConverter().fromJson(
    json['subscriptionUpdatedAt'],
  ),
);

Map<String, dynamic> _$ClinicModelToJson(
  ClinicModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'ownerId': instance.ownerId,
  'adminEmail': instance.adminEmail,
  'createdAt': const NullableTimestampConverter().toJson(instance.createdAt),
  'subscriptionTier': instance.subscriptionTier,
  'isSubscriptionActive': instance.isSubscriptionActive,
  'subscriptionUpdatedAt': const NullableTimestampConverter().toJson(
    instance.subscriptionUpdatedAt,
  ),
};
