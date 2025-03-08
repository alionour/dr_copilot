import 'package:json_annotation/json_annotation.dart';

part 'session_model.g.dart';

/// A model class representing a patient.
@JsonSerializable()
class SessionModel {
  final String id;
  final String title;
  final String description;

  SessionModel({
    required this.id,
    required this.title,
    required this.description,
  });

  /// A factory constructor to create a Patient instance from a JSON map.
  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  /// A method to convert a Patient instance to a JSON map.
  Map<String, dynamic> toJson() => _$SessionModelToJson(this);
}
