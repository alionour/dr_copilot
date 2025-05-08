// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'currency_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrencyProfileModel _$CurrencyProfileModelFromJson(
        Map<String, dynamic> json) =>
    CurrencyProfileModel(
      id: json['id'] as String,
      currency: json['currency'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$CurrencyProfileModelToJson(
        CurrencyProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'currency': instance.currency,
      'name': instance.name,
      'description': instance.description,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
