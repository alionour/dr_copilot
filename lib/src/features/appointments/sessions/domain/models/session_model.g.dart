// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      price: (json['price'] as num).toDouble(),
      startDateTime: const TimestampConverter().fromJson(json['startDateTime']),
      endDateTime: const TimestampConverter().fromJson(json['endDateTime']),
      sessionType: $enumDecode(_$SessionTypeEnumMap, json['sessionType']),
      userId: json['userId'] as String,
      createdBy: json['createdBy'] as String,
      patientName: json['patientName'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: const TimestampConverter().fromJson(json['deletedAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$SessionModelToJson(SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'price': instance.price,
      'startDateTime':
          const TimestampConverter().toJson(instance.startDateTime),
      'endDateTime': const TimestampConverter().toJson(instance.endDateTime),
      'sessionType': _$SessionTypeEnumMap[instance.sessionType]!,
      'userId': instance.userId,
      'createdBy': instance.createdBy,
      'patientName': instance.patientName,
      'updatedBy': instance.updatedBy,
      'deletedBy': instance.deletedBy,
      'deletedAt': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.deletedAt, const TimestampConverter().toJson),
      'createdAt': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.createdAt, const TimestampConverter().toJson),
      'updatedAt': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.updatedAt, const TimestampConverter().toJson),
    };

const _$SessionTypeEnumMap = {
  SessionType.pediatricIntensive: 'pediatricIntensive',
  SessionType.adultIntensive: 'adultIntensive',
  SessionType.standard: 'standard',
  SessionType.traction: 'traction',
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
