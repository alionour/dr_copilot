import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient_model.g.dart';

/// A model class representing a patient.
@JsonSerializable()
class PatientModel {
  /// The unique identifier of the patient.
  final String id;

  /// The full name of the patient.
  final String name;

  /// The age of the patient (optional).
  final int? age;

  /// The gender of the patient (optional).
  final String? gender;

  /// The address of the patient (optional).
  final String? address;

  /// The ID of the owner/creator of the patient record.
  final String ownerId;

  /// The ID of the clinic the patient belongs to.
  final String clinicId;

  /// The patient's phone number.
  final String? phoneNumber;

  /// An alternative phone number for the patient.
  final String? alternativePhoneNumber;

  /// The doctor treating the patient.
  final String? treatingDoctor;

  /// The patient's occupation.
  final String? occupation;

  /// The timestamp when the patient record was created.
  @TimestampConverter()
  final Timestamp? createdAt;

  /// The timestamp when the patient record was last updated.
  @TimestampConverter()
  final Timestamp? updatedAt;

  /// The ID of the user who created the record.
  final String? createdBy;

  /// The ID of the user who last updated the record.
  final String? updatedBy;

  /// The ID of the user who deleted the record (if soft deleted).
  final String? deletedBy;

  /// The timestamp when the record was soft deleted.
  @TimestampConverter()
  final Timestamp? deletedAt;

  /// The ID of the team the patient is assigned to.
  final String? teamId;

  /// Creates a new [PatientModel] instance.
  PatientModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.address,
    required this.ownerId,
    required this.clinicId,
    this.phoneNumber,
    this.alternativePhoneNumber,
    this.treatingDoctor,
    this.teamId,
    this.occupation,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
  });

  /// Creates a [PatientModel] from a JSON map.
  factory PatientModel.fromJson(Map<String, dynamic> json) =>
      _$PatientModelFromJson(json);

  /// Converts the [PatientModel] to a JSON map.
  Map<String, dynamic> toJson() => _$PatientModelToJson(this);

  /// Creates a copy of this [PatientModel] with the given fields replaced with new values.
  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    String? address,
    String? ownerId,
    String? clinicId,
    String? phoneNumber,
    String? alternativePhoneNumber,
    String? treatingDoctor,
    String? teamId,
    String? occupation,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    Timestamp? deletedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      ownerId: ownerId ?? this.ownerId,
      clinicId: clinicId ?? this.clinicId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternativePhoneNumber:
          alternativePhoneNumber ?? this.alternativePhoneNumber,
      treatingDoctor: treatingDoctor ?? this.treatingDoctor,
      teamId: teamId ?? this.teamId,
      occupation: occupation ?? this.occupation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class TimestampConverter implements JsonConverter<Timestamp?, dynamic> {
  const TimestampConverter();

  @override
  Timestamp? fromJson(dynamic json) {
    if (json == null) {
      return null;
    } else if (json is Timestamp) {
      return json;
    } else if (json is int) {
      return Timestamp.fromMillisecondsSinceEpoch(json);
    } else if (json is String) {
      return Timestamp.fromDate(DateTime.parse(json));
    } else {
      throw Exception('Invalid type for Timestamp conversion: $json');
    }
  }

  @override
  dynamic toJson(Timestamp? object) => object;
}
