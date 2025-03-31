import 'package:json_annotation/json_annotation.dart';

part 'session_model.g.dart';

/// Enum for session types
enum SessionType {
  pediatricIntensive('Pediatric Intensive', 100.0),
  adultIntensive('Adult Intensive', 150.0),
  standard('Standard', 120.0),
  traction('Traction', 150.0);

  final String text;
  final double basePrice;

  const SessionType(this.text, this.basePrice);
}

/// A model class representing a session.
@JsonSerializable()
class SessionModel {
  final String id;
  final String patientName;
  final double price;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final SessionType sessionType;

  SessionModel({
    required this.id,
    required this.patientName,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    required this.sessionType,
  });

  /// A factory constructor to create a SessionModel instance from a JSON map.
  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  /// A method to convert a SessionModel instance to a JSON map.
  Map<String, dynamic> toJson() => _$SessionModelToJson(this);
}
