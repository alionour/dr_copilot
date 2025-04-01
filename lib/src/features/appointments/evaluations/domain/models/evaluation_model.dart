import 'package:json_annotation/json_annotation.dart';

part 'evaluation_model.g.dart';

/// A model class representing an evaluation.
@JsonSerializable()
class EvaluationModel {
  final String id;
  final String title;
  final String description;
  

  EvaluationModel({
    required this.id,
    required this.title,
    required this.description,
  });

  /// A factory constructor to create an EvaluationModel instance from a JSON map.
  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  /// A method to convert an EvaluationModel instance to a JSON map.
  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);
}
