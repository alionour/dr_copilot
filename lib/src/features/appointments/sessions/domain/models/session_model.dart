import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_model.g.dart';

/// Class for session type presets
class SessionTypePresets {
  static const String pediatricIntensive = 'Pediatric Intensive';
  static const String adultIntensive = 'Adult Intensive';
  static const String standard = 'Standard';
  static const String traction = 'Traction';
  static const String custom = 'Custom';

  static const List<String> values = [
    pediatricIntensive,
    adultIntensive,
    standard,
    traction,
    custom,
  ];

  static const Map<String, double> basePrices = {
    pediatricIntensive: 100.0,
    adultIntensive: 150.0,
    standard: 120.0,
    traction: 150.0,
    custom: 0.0,
  };
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

  final String? sessionType;
  final String ownerId;
  final String clinicId;
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

  final String? doctorId;
  final String? departmentId;
  final String? teamId;

  SessionModel({
    required this.id,
    required this.patientId,
    required this.price,
    required this.startDateTime,
    required this.endDateTime,
    this.sessionType,
    required this.ownerId,
    required this.clinicId,
    required this.createdBy,
    this.patientName,
    this.updatedBy,
    this.deletedBy,
    this.deletedAt,
    required this.createdAt,
    this.updatedAt,
    this.doctorId,
    this.departmentId,
    this.teamId,
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
    String? sessionType,
    String? ownerId,
    String? clinicId,
    String? createdBy,
    String? patientName,
    String? updatedBy,
    String? deletedBy,
    Timestamp? deletedAt,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? doctorId,
    String? departmentId,
    String? teamId,
  }) {
    return SessionModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      price: price ?? this.price,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      sessionType: sessionType ?? this.sessionType,
      ownerId: ownerId ?? this.ownerId,
      clinicId: clinicId ?? this.clinicId,
      createdBy: createdBy ?? this.createdBy,
      patientName: patientName ?? this.patientName,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      doctorId: doctorId ?? this.doctorId,
      departmentId: departmentId ?? this.departmentId,
      teamId: teamId ?? this.teamId,
    );
  }
}

