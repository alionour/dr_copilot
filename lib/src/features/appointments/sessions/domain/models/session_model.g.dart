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
  sessionType: json['sessionType'] as String?,
  ownerId: json['ownerId'] as String,
  clinicId: json['clinicId'] as String,
  createdBy: json['createdBy'] as String,
  patientName: json['patientName'] as String?,
  updatedBy: json['updatedBy'] as String?,
  deletedBy: json['deletedBy'] as String?,
  deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
  doctorId: json['doctorId'] as String?,
);

Map<String, dynamic> _$SessionModelToJson(
  SessionModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'patientId': instance.patientId,
  'price': instance.price,
  'startDateTime': const TimestampConverter().toJson(instance.startDateTime),
  'endDateTime': const TimestampConverter().toJson(instance.endDateTime),
  'sessionType': instance.sessionType,
  'ownerId': instance.ownerId,
  'clinicId': instance.clinicId,
  'createdBy': instance.createdBy,
  'patientName': instance.patientName,
  'updatedBy': instance.updatedBy,
  'deletedBy': instance.deletedBy,
  'deletedAt': const NullableTimestampConverter().toJson(instance.deletedAt),
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'doctorId': instance.doctorId,
};
