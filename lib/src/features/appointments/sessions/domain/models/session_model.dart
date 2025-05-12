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
class SessionModel {
  final String id;
  final String patientId;
  final double price;

  @TimestampConverter()
  final Timestamp startDateTime;

  @TimestampConverter()
  final Timestamp endDateTime;

  final SessionType? sessionType;
  final String userId;
  final String createdBy;
  final String? patientName;
  final String? updatedBy;
  final String? deletedBy;

  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  @TimestampConverter()
  final Timestamp createdAt;

  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  SessionModel({
    required this.id,
    required this.patientId,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    this.sessionType,
    required this.userId,
    required this.createdBy,
    this.patientName,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModelToJson(this);

  SessionModel copyWith({
    String? id,
    String? patientId,
    double? price,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    SessionType? sessionType,
    String? userId,
    String? createdBy,
    String? patientName,
    String? updatedBy,
    String? deletedBy,
    Timestamp? deletedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return SessionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      price: price ?? this.price,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      sessionType: sessionType ?? this.sessionType,
      userId: userId ?? this.userId,
      createdBy: createdBy ?? this.createdBy,
      patientName: patientName ?? this.patientName,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
