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

  /// Constructor for the Patient class.
  PatientModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.address,
  });

  /// A factory constructor to create a Patient instance from a JSON map.
  factory PatientModel.fromJson(Map<String, dynamic> json) =>
      _$PatientModelFromJson(json);

  /// A method to convert a Patient instance to a JSON map.
  Map<String, dynamic> toJson() => _$PatientModelToJson(this);
}
