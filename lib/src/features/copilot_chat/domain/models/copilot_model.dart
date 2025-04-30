import 'package:json_annotation/json_annotation.dart';

part 'copilot_model.g.dart';

/// A model class representing a copilot.
@JsonSerializable()
class CopilotModel {
  final String id;
  final String name;
  final String role;

  /// Constructor for the Copilot class.
  CopilotModel({
    required this.id,
    required this.name,
    required this.role,
  });

  /// A factory constructor to create a Copilot instance from a JSON map.
  factory CopilotModel.fromJson(Map<String, dynamic> json) =>
      _$CopilotModelFromJson(json);

  /// A method to convert a Copilot instance to a JSON map.
  Map<String, dynamic> toJson() => _$CopilotModelToJson(this);
}
