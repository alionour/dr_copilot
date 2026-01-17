import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calendar_event_model.g.dart';

/// Event types for calendar events
enum CalendarEventType {
  session, // Auto-created from SessionModel
  evaluation, // Auto-created from EvaluationModel
  appointment, // General patient appointment (created by staff)
  meeting, // Team meetings
  reminder, // Personal reminders/tasks
  holiday, // Clinic holidays/closures
  vacation, // Doctor/staff time off
  unavailable, // Doctor not available (blocked time)
  clinicClosure, // Clinic closed (maintenance, etc.)
  custom, // General purpose event
}

/// Recurrence patterns for events
enum EventRecurrence {
  none, // Single event
  daily, // Repeats daily
  weekly, // Repeats weekly
  monthly, // Repeats monthly
}

/// Timestamp converter for Firestore Timestamp fields
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

/// Nullable timestamp converter for optional Firestore Timestamp fields
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

/// Calendar event model stored in Firestore
/// Collection: calendar_events
@JsonSerializable()
class CalendarEventModel {
  /// Unique event ID (Firestore document ID)
  final String id;

  /// Event title/summary
  final String title;

  /// Event start date and time
  @TimestampConverter()
  final Timestamp startDateTime;

  /// Event end date and time
  @TimestampConverter()
  final Timestamp endDateTime;

  /// Type of event (session, evaluation, meeting, etc.)
  final String eventType;

  /// Clinic this event belongs to
  final String clinicId;

  /// User who created this event
  final String createdBy;

  /// When this event was created
  @TimestampConverter()
  final Timestamp createdAt;

  /// Assigned doctor/staff member (optional)
  final String? doctorId;

  /// Patient ID (for session/evaluation/appointment events)
  final String? patientId;

  /// Link to session document (if eventType is 'session')
  final String? sessionId;

  /// Link to evaluation document (if eventType is 'evaluation')
  final String? evaluationId;

  /// Event description/notes
  final String? description;

  /// Physical location
  final String? location;

  /// Custom color code for the event
  final String? color;

  /// If true, visible to all clinic staff; if false, only to assigned doctor
  final bool isClinicWide;

  /// Recurrence pattern (none, daily, weekly, monthly)
  final String? recurrence;

  /// User who last updated this event
  final String? updatedBy;

  /// When this event was last updated
  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  /// User who soft-deleted this event
  final String? deletedBy;

  /// When this event was soft-deleted
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  CalendarEventModel({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    required this.eventType,
    required this.clinicId,
    required this.createdBy,
    required this.createdAt,
    this.doctorId,
    this.patientId,
    this.sessionId,
    this.evaluationId,
    this.description,
    this.location,
    this.color,
    this.isClinicWide = false,
    this.recurrence,
    this.updatedBy,
    this.updatedAt,
    this.deletedBy,
    this.deletedAt,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarEventModelToJson(this);

  CalendarEventModel copyWith({
    String? id,
    String? title,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    String? eventType,
    String? clinicId,
    String? createdBy,
    Timestamp? createdAt,
    String? doctorId,
    String? patientId,
    String? sessionId,
    String? evaluationId,
    String? description,
    String? location,
    String? color,
    bool? isClinicWide,
    String? recurrence,
    String? updatedBy,
    Timestamp? updatedAt,
    String? deletedBy,
    Timestamp? deletedAt,
  }) {
    return CalendarEventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      eventType: eventType ?? this.eventType,
      clinicId: clinicId ?? this.clinicId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      sessionId: sessionId ?? this.sessionId,
      evaluationId: evaluationId ?? this.evaluationId,
      description: description ?? this.description,
      location: location ?? this.location,
      color: color ?? this.color,
      isClinicWide: isClinicWide ?? this.isClinicWide,
      recurrence: recurrence ?? this.recurrence,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Check if event is deleted (soft delete)
  bool get isDeleted => deletedAt != null;

  /// Get the event type from string
  CalendarEventType get type {
    switch (eventType.toLowerCase()) {
      case 'session':
        return CalendarEventType.session;
      case 'evaluation':
        return CalendarEventType.evaluation;
      case 'appointment':
        return CalendarEventType.appointment;
      case 'meeting':
        return CalendarEventType.meeting;
      case 'reminder':
        return CalendarEventType.reminder;
      case 'holiday':
        return CalendarEventType.holiday;
      case 'vacation':
        return CalendarEventType.vacation;
      case 'unavailable':
        return CalendarEventType.unavailable;
      case 'clinicclosure':
      case 'clinic_closure':
        return CalendarEventType.clinicClosure;
      default:
        return CalendarEventType.custom;
    }
  }
}

