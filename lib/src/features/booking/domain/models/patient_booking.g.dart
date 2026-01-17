// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatientBooking _$PatientBookingFromJson(Map<String, dynamic> json) =>
    PatientBooking(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      doctorId: json['doctorId'] as String?,
      requestedTime: DateTime.parse(json['requestedTime'] as String),
      patientName: json['patientName'] as String,
      patientPhone: json['patientPhone'] as String,
      patientEmail: json['patientEmail'] as String?,
      reason: json['reason'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      confirmedBy: json['confirmedBy'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PatientBookingToJson(PatientBooking instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clinicId': instance.clinicId,
      'doctorId': instance.doctorId,
      'requestedTime': instance.requestedTime.toIso8601String(),
      'patientName': instance.patientName,
      'patientPhone': instance.patientPhone,
      'patientEmail': instance.patientEmail,
      'reason': instance.reason,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'confirmedBy': instance.confirmedBy,
      'notes': instance.notes,
    };
