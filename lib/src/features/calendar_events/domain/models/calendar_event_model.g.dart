// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEventModel _$CalendarEventModelFromJson(Map<String, dynamic> json) =>
    CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startDateTime: const TimestampConverter().fromJson(json['startDateTime']),
      endDateTime: const TimestampConverter().fromJson(json['endDateTime']),
      eventType: json['eventType'] as String,
      clinicId: json['clinicId'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      doctorId: json['doctorId'] as String?,
      patientId: json['patientId'] as String?,
      sessionId: json['sessionId'] as String?,
      evaluationId: json['evaluationId'] as String?,
      description: json['description'] as String?,
      location: json['location'] as String?,
      color: json['color'] as String?,
      isClinicWide: json['isClinicWide'] as bool? ?? false,
      recurrence: json['recurrence'] as String?,
      updatedBy: json['updatedBy'] as String?,
      updatedAt: const NullableTimestampConverter().fromJson(json['updatedAt']),
      deletedBy: json['deletedBy'] as String?,
      deletedAt: const NullableTimestampConverter().fromJson(json['deletedAt']),
    );

Map<String, dynamic> _$CalendarEventModelToJson(
  CalendarEventModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'startDateTime': const TimestampConverter().toJson(instance.startDateTime),
  'endDateTime': const TimestampConverter().toJson(instance.endDateTime),
  'eventType': instance.eventType,
  'clinicId': instance.clinicId,
  'createdBy': instance.createdBy,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'doctorId': instance.doctorId,
  'patientId': instance.patientId,
  'sessionId': instance.sessionId,
  'evaluationId': instance.evaluationId,
  'description': instance.description,
  'location': instance.location,
  'color': instance.color,
  'isClinicWide': instance.isClinicWide,
  'recurrence': instance.recurrence,
  'updatedBy': instance.updatedBy,
  'updatedAt': const NullableTimestampConverter().toJson(instance.updatedAt),
  'deletedBy': instance.deletedBy,
  'deletedAt': const NullableTimestampConverter().toJson(instance.deletedAt),
};

