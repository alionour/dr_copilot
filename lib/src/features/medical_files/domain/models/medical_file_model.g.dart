// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedicalFileModel _$MedicalFileModelFromJson(Map<String, dynamic> json) =>
    MedicalFileModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      fileUrl: json['fileUrl'] as String?,
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
      uploadedBy: json['uploadedBy'] as String,
      metadata: (json['metadata'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$MedicalFileModelToJson(MedicalFileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'title': instance.title,
      'type': instance.type,
      'fileUrl': instance.fileUrl,
      'date': instance.date.toIso8601String(),
      'description': instance.description,
      'uploadedBy': instance.uploadedBy,
      'metadata': instance.metadata,
      'createdAt': instance.createdAt.toIso8601String(),
    };

