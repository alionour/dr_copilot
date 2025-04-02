import 'package:cloud_firestore/cloud_firestore.dart';
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

class TimestampConverter implements JsonConverter<Timestamp, dynamic> {
  const TimestampConverter();

  @override
  Timestamp fromJson(dynamic json) {
    return json is Timestamp
        ? json
        : Timestamp.fromMillisecondsSinceEpoch(json as int);
  }

  @override
  dynamic toJson(Timestamp object) => object;
}

@JsonSerializable()
class SessionModel {
  final String id;
  final String patientName;
  final double price;

  @TimestampConverter()
  final Timestamp startDateTime;

  @TimestampConverter()
  final Timestamp endDateTime;

  final SessionType sessionType;
  final String userId;
  final String createdBy;

  SessionModel({
    required this.id,
    required this.patientName,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    required this.sessionType,
    required this.userId,
    required this.createdBy,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModelToJson(this);

  SessionModel copyWith({
    String? id,
    String? patientName,
    double? price,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    SessionType? sessionType,
    String? userId,
    String? createdBy,
  }) {
    return SessionModel(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      price: price ?? this.price,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      sessionType: sessionType ?? this.sessionType,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
