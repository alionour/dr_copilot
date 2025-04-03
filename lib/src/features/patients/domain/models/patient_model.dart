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
  final String userId;

  @TimestampConverter()
  final Timestamp? createdAt;

  @TimestampConverter()
  final Timestamp? updatedAt;

  /// Constructor for the Patient class.
  PatientModel({
    required this.id,
    required this.name,
    this.age,
    this.gender,
    this.address,
    required this.userId,
    this.createdAt,
    this.updatedAt,
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
    String? userId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimestampConverter implements JsonConverter<Timestamp, dynamic> {
  const TimestampConverter();

  @override
  Timestamp fromJson(dynamic json) {
    if (json is Timestamp) {
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
  dynamic toJson(Timestamp object) => object;
}
