// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationModel _$EvaluationModelFromJson(Map<String, dynamic> json) =>
    EvaluationModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      price: (json['price'] as num).toDouble(),
      startDateTime: const TimestampConverter().fromJson(json['startDateTime']),
      endDateTime: const TimestampConverter().fromJson(json['endDateTime']),
      userId: json['userId'] as String,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      deletedAt: const TimestampConverter().fromJson(json['deletedAt']),
    );

Map<String, dynamic> _$EvaluationModelToJson(EvaluationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'patientName': instance.patientName,
      'price': instance.price,
      'startDateTime':
          const TimestampConverter().toJson(instance.startDateTime),
      'endDateTime': const TimestampConverter().toJson(instance.endDateTime),
      'userId': instance.userId,
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'deletedBy': instance.deletedBy,
      'createdAt': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.createdAt, const TimestampConverter().toJson),
      'updatedAt': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.updatedAt, const TimestampConverter().toJson),
      'deletedAt': _$JsonConverterToJson<dynamic, Timestamp>(
          instance.deletedAt, const TimestampConverter().toJson),
    };

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
