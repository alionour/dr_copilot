import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart'; // For TimestampConverter

part 'medical_file_model.g.dart';

@JsonSerializable()
class MedicalFileModel extends Equatable {
  final String id;
  final String patientId;
  final String title;
  final String type; // e.g., 'X-Ray', 'Lab Report', 'MRI', 'Other'
  final String? fileUrl;

  @TimestampConverter()
  final DateTime date;

  final String? description;
  final String uploadedBy;
  final Map<String, String>?
  metadata; // For "two pair values" like {"Result": "Positive"}

  @TimestampConverter()
  final DateTime createdAt;

  const MedicalFileModel({
    required this.id,
    required this.patientId,
    required this.title,
    required this.type,
    this.fileUrl,
    required this.date,
    this.description,
    required this.uploadedBy,
    this.metadata,
    required this.createdAt,
  });

  factory MedicalFileModel.fromJson(Map<String, dynamic> json) =>
      _$MedicalFileModelFromJson(json);

  Map<String, dynamic> toJson() => _$MedicalFileModelToJson(this);

  MedicalFileModel copyWith({
    String? id,
    String? patientId,
    String? title,
    String? type,
    String? fileUrl,
    DateTime? date,
    String? description,
    String? uploadedBy,
    Map<String, String>? metadata,
    DateTime? createdAt,
  }) {
    return MedicalFileModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      date: date ?? this.date,
      description: description ?? this.description,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    title,
    type,
    fileUrl,
    date,
    description,
    uploadedBy,
    metadata,
    createdAt,
  ];
}

