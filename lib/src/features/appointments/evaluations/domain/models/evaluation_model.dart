import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'evaluation_model.g.dart';

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
  dynamic toJson(Timestamp? object) => object;
}

class NullableTimestampConverter implements JsonConverter<Timestamp?, dynamic> {
  const NullableTimestampConverter();

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

@JsonSerializable()

/// A model class representing a patient evaluation.
@JsonSerializable()
class EvaluationModel {
  /// The unique identifier of the evaluation.
  final String id;

  /// The ID of the patient being evaluated.
  final String patientId;

  /// The name of the patient (denormalized).
  final String patientName;

  /// The cost/price of the evaluation.
  final double price;

  /// The start date and time of the evaluation.
  @TimestampConverter()
  final Timestamp startDateTime;

  /// The end date and time of the evaluation.
  @TimestampConverter()
  final Timestamp endDateTime;

  /// The ID of the owner/clinic admin.
  final String ownerId;

  /// The ID of the clinic where the evaluation is held.
  final String clinicId;

  /// The ID of the user who created the evaluation record.
  final String createdBy;

  /// The ID of the user who last updated the evaluation record.
  final String? updatedBy;

  /// The ID of the user who deleted the evaluation record (if soft deleted).
  final String? deletedBy;

  /// The timestamp when the evaluation record was created.
  @TimestampConverter()
  final Timestamp createdAt;

  /// The timestamp when the evaluation record was last updated.
  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  /// The timestamp when the evaluation record was soft deleted.
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  /// The ID of the doctor conducting the evaluation.
  final String? doctorId;

  EvaluationModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    required this.ownerId,
    required this.clinicId,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.doctorId,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);

  EvaluationModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    double? price,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    String? ownerId,
    String? clinicId,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? doctorId,
  }) {
    return EvaluationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      price: price ?? this.price,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      ownerId: ownerId ?? this.ownerId,
      clinicId: clinicId ?? this.clinicId,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      doctorId: doctorId ?? this.doctorId,
    );
  }
}
