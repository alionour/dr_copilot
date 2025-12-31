import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'session_model.g.dart';

/// Class for session type presets
/// Class defining preset types for sessions with standard names.
class SessionTypePresets {
  /// Preset for Pediatric Intensive sessions.
  static const String pediatricIntensive = 'Pediatric Intensive';

  /// Preset for Adult Intensive sessions.
  static const String adultIntensive = 'Adult Intensive';

  /// Preset for Standard sessions.
  static const String standard = 'Standard';

  /// Preset for Traction sessions.
  static const String traction = 'Traction';

  /// Preset for Custom sessions.
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

/// A model class representing a therapy session.
@JsonSerializable()
class SessionModel {
  /// The unique identifier of the session.
  final String id;

  /// The ID of the patient attending the session.
  final String patientId;

  /// The cost/price of the session.
  final double price;

  /// The start date and time of the session.
  @TimestampConverter()
  final Timestamp startDateTime;

  /// The end date and time of the session.
  @TimestampConverter()
  final Timestamp endDateTime;

  /// The type of the session (e.g., Standard, Intensive).
  final String? sessionType;

  /// The ID of the owner/clinic admin.
  final String ownerId;

  /// The ID of the clinic where the session is held.
  final String clinicId;

  /// The ID of the user who created the session record.
  final String createdBy;

  /// The name of the patient (denormalized for convenient display).
  final String? patientName;

  /// The ID of the user who last updated the session record.
  final String? updatedBy;

  /// The ID of the user who deleted the session record (if soft deleted).
  final String? deletedBy;

  /// The timestamp when the session was soft deleted.
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  /// The timestamp when the session record was created.
  @TimestampConverter()
  final Timestamp createdAt;

  /// The timestamp when the session record was last updated.
  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  /// The ID of the doctor conducting the session.
  final String? doctorId;

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
    );
  }
}
