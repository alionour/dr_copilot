// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'telemedicine_meeting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TelemedicineMeeting _$TelemedicineMeetingFromJson(Map<String, dynamic> json) =>
    TelemedicineMeeting(
      id: json['id'] as String,
      appointmentId: json['appointmentId'] as String,
      roomId: json['roomId'] as String,
      meetingLink: json['meetingLink'] as String,
      doctorId: json['doctorId'] as String,
      patientId: json['patientId'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      status: json['status'] as String,
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      platform: json['platform'] as String? ?? 'web',
    );

Map<String, dynamic> _$TelemedicineMeetingToJson(
        TelemedicineMeeting instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appointmentId': instance.appointmentId,
      'roomId': instance.roomId,
      'meetingLink': instance.meetingLink,
      'doctorId': instance.doctorId,
      'patientId': instance.patientId,
      'scheduledTime': instance.scheduledTime.toIso8601String(),
      'status': instance.status,
      'startedAt': instance.startedAt?.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'durationMinutes': instance.durationMinutes,
      'platform': instance.platform,
    };
