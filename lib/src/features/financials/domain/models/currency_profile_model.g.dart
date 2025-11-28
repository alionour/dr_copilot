// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyProfileModel _$CurrencyProfileModelFromJson(
  Map<String, dynamic> json,
) => CurrencyProfileModel(
  id: json['id'] as String,
  currency: json['currency'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
  createdBy: json['createdBy'] as String,
  updatedBy: json['updatedBy'] as String?,
  deletedBy: json['deletedBy'] as String?,
);

Map<String, dynamic> _$CurrencyProfileModelToJson(
  CurrencyProfileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'currency': instance.currency,
  'name': instance.name,
  'description': instance.description,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'deletedAt': const NullableTimestampConverter().toJson(instance.deletedAt),
  'createdBy': instance.createdBy,
  'updatedBy': instance.updatedBy,
  'deletedBy': instance.deletedBy,
};
