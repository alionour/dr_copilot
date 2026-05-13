import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient_model.g.dart';

/// A model class representing a patient.
@JsonSerializable()
class PatientModel {
  final String id;
  final String name;
  final int? age;
  final String? gender;
  final String? address;
  final String ownerId;
  final String clinicId;
  final String? phoneNumber;
  final String? alternativePhoneNumber;
  final String? treatingDoctor;
  final String? treatingDoctorId;
  final String? occupation;

  @TimestampConverter()
  final Timestamp? createdAt;

  @TimestampConverter()
  final Timestamp? updatedAt;

  final String? createdBy;
  final String? updatedBy;
  final String? deletedBy;

  @TimestampConverter()
  final Timestamp? deletedAt;

  /// Constructor for the Patient class.
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
    this.treatingDoctorId,
    this.occupation,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
  });

  /// A factory constructor to create a Patient instance from a JSON map.
  factory PatientModel.fromJson(Map<String, dynamic> json) =>
      _$PatientModelFromJson(json);

  /// A method to convert a Patient instance to a JSON map.
  Map<String, dynamic> toJson() => _$PatientModelToJson(this);

  /// A copyWith method to create a new instance with updated fields.
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
    String? treatingDoctorId,
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
      treatingDoctorId: treatingDoctorId ?? this.treatingDoctorId,
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

