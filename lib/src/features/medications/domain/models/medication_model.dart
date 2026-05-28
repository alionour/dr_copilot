import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart'; // For TimestampConverter

part 'medication_model.g.dart';

@JsonSerializable()
class MedicationModel extends Equatable {
  final String id;
  final String patientId;
  final String clinicId;
  final String name;
  final String? dosage;
  final String? frequency;

  @TimestampConverter()
  final DateTime startDate;

  @TimestampConverter()
  final DateTime? endDate;

  final String? instructions;
  final String? prescribedBy;

  final String? fileUrl; // For prescription image

  @TimestampConverter()
  final DateTime createdAt;

  const MedicationModel({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.name,
    this.dosage,
    this.frequency,
    required this.startDate,
    this.endDate,
    this.instructions,
    this.prescribedBy,
    this.fileUrl,
    required this.createdAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) =>
      _$MedicationModelFromJson(json);

  Map<String, dynamic> toJson() => _$MedicationModelToJson(this);

  MedicationModel copyWith({
    String? id,
    String? patientId,
    String? clinicId,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    String? instructions,
    String? prescribedBy,
    String? fileUrl,
    DateTime? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      clinicId: clinicId ?? this.clinicId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      instructions: instructions ?? this.instructions,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      fileUrl: fileUrl ?? this.fileUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    patientId,
    clinicId,
    name,
    dosage,
    frequency,
    startDate,
    endDate,
    instructions,
    prescribedBy,
    fileUrl,
    createdAt,
  ];
}

