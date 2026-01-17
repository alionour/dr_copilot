import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'telemedicine_meeting.g.dart';

/// Model for telemedicine video consultation meetings
@JsonSerializable()
class TelemedicineMeeting extends Equatable {
  final String id;
  final String appointmentId;
  final String roomId;
  final String meetingLink;
  final String doctorId;
  final String patientId;
  final DateTime scheduledTime;
  final String status; // 'scheduled', 'inProgress', 'completed', 'cancelled'
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? durationMinutes;
  final String? platform; // 'agora', 'zoom', 'jitsi'

  const TelemedicineMeeting({
    required this.id,
    required this.appointmentId,
    required this.roomId,
    required this.meetingLink,
    required this.doctorId,
    required this.patientId,
    required this.scheduledTime,
    required this.status,
    this.startedAt,
    this.endedAt,
    this.durationMinutes,
    this.platform = 'web',
  });

  factory TelemedicineMeeting.fromJson(Map<String, dynamic> json) =>
      _$TelemedicineMeetingFromJson(json);

  Map<String, dynamic> toJson() => _$TelemedicineMeetingToJson(this);

  TelemedicineMeeting copyWith({
    String? id,
    String? appointmentId,
    String? roomId,
    String? meetingLink,
    String? doctorId,
    String? patientId,
    DateTime? scheduledTime,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    String? platform,
  }) {
    return TelemedicineMeeting(
      id: id ?? this.id,
      appointmentId: appointmentId ?? this.appointmentId,
      roomId: roomId ?? this.roomId,
      meetingLink: meetingLink ?? this.meetingLink,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      platform: platform ?? this.platform,
    );
  }

  @override
  List<Object?> get props => [
        id,
        appointmentId,
        roomId,
        meetingLink,
        doctorId,
        patientId,
        scheduledTime,
        status,
        startedAt,
        endedAt,
        durationMinutes,
        platform,
      ];
}
