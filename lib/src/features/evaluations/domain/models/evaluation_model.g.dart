// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationModel _$EvaluationModelFromJson(Map<String, dynamic> json) =>
    EvaluationModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      notes: json['notes'] as String,
      date: DateTime.parse(json['date'] as String),
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$EvaluationModelToJson(EvaluationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'notes': instance.notes,
      'date': instance.date.toIso8601String(),
      'userId': instance.userId,
    };
