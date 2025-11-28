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
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$ClinicModelToJson(ClinicModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'ownerId': instance.ownerId,
      'adminEmail': instance.adminEmail,
      'createdAt': _$JsonConverterToJson<dynamic, Timestamp>(
        instance.createdAt,
        const TimestampConverter().toJson,
      ),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
