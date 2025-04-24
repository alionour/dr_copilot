// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      price: (json['price'] != null) ? (json['price'] as num).toDouble() : 0.0,
      startDateTime: const TimestampConverter().fromJson(json['startDateTime']),
      endDateTime: const TimestampConverter().fromJson(json['endDateTime']),
      sessionType: json['sessionType'] != null
          ? $enumDecodeNullable(_$SessionTypeEnumMap, json['sessionType'])
          : null,
      userId: json['userId'] as String,
      createdBy: json['createdBy'] as String,
      patientName: json['patientName'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
      createdAt: const NullableTimestampConverter().fromJson(json['createdAt']),
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
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
      'deletedAt':
          const NullableTimestampConverter().toJson(instance.deletedAt),
      'createdAt':
          const NullableTimestampConverter().toJson(instance.createdAt),
      'updatedAt':
          const NullableTimestampConverter().toJson(instance.updatedAt),
    };

const _$SessionTypeEnumMap = {
  SessionType.pediatricIntensive: 'pediatricIntensive',
  SessionType.adultIntensive: 'adultIntensive',
  SessionType.standard: 'standard',
  SessionType.traction: 'traction',
};
