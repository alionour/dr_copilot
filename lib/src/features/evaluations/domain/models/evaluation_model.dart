import 'package:json_annotation/json_annotation.dart';

part 'evaluation_model.g.dart';

/// A model class representing an evaluation.
@JsonSerializable()
class EvaluationModel {
  final String id;
  final String patientId;
  final String notes;
  final DateTime date;
  final String userId; // Add userId field

  EvaluationModel({
    required this.id,
    required this.patientId,
    required this.notes,
    required this.date,
    required this.userId, // Initialize userId
  });

  /// A factory constructor to create an EvaluationModel instance from a JSON map.
  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  /// A method to convert an EvaluationModel instance to a JSON map.
  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);

  /// Creates a copy of this EvaluationModel with updated fields.
  EvaluationModel copyWith({
    String? id,
    String? patientId,
    String? notes,
    DateTime? date,
    String? userId, // Add userId to copyWith
  }) {
    return EvaluationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      userId: userId ?? this.userId, // Copy userId
    );
  }
}
