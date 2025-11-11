import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clinic_model.g.dart';

@JsonSerializable()
class ClinicModel {
  final String id;
  final String name;
  final String? location;
  final String ownerId;
  final String adminEmail;
  @TimestampConverter()
  final Timestamp? createdAt;

  ClinicModel({
    required this.id,
    required this.name,
    required this.location,
    required this.ownerId,
    required this.adminEmail,
    required this.createdAt,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) =>
      _$ClinicModelFromJson(json);
  Map<String, dynamic> toJson() => _$ClinicModelToJson(this);

  ClinicModel copyWith({
    String? id,
    String? name,
    String? location,
    String? ownerId,
    String? adminEmail,
    Timestamp? createdAt,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      ownerId: ownerId ?? this.ownerId,
      adminEmail: adminEmail ?? this.adminEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
