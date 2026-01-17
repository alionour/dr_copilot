import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient_booking.g.dart';

/// Model for patient self-booking requests
@JsonSerializable()
class PatientBooking extends Equatable {
  final String id;
  final String clinicId;
  final String? doctorId;
  final DateTime requestedTime;
  final String patientName;
  final String patientPhone;
  final String? patientEmail;
  final String reason;
  final String status; // 'pending', 'confirmed', 'rejected', 'cancelled'
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final String? confirmedBy; // staff user ID who approved
  final String? notes;

  const PatientBooking({
    required this.id,
    required this.clinicId,
    this.doctorId,
    required this.requestedTime,
    required this.patientName,
    required this.patientPhone,
    this.patientEmail,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
    this.confirmedBy,
    this.notes,
  });

  factory PatientBooking.fromJson(Map<String, dynamic> json) =>
      _$PatientBookingFromJson(json);

  Map<String, dynamic> toJson() => _$PatientBookingToJson(this);

  PatientBooking copyWith({
    String? id,
    String? clinicId,
    String? doctorId,
    DateTime? requestedTime,
    String? patientName,
    String? patientPhone,
    String? patientEmail,
    String? reason,
    String? status,
    DateTime? createdAt,
    DateTime? confirmedAt,
    String? confirmedBy,
    String? notes,
  }) {
    return PatientBooking(
      id: id ?? this.id,
      clinicId: clinicId ?? this.clinicId,
      doctorId: doctorId ?? this.doctorId,
      requestedTime: requestedTime ?? this.requestedTime,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
      patientEmail: patientEmail ?? this.patientEmail,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clinicId,
        doctorId,
        requestedTime,
        patientName,
        patientPhone,
        patientEmail,
        reason,
        status,
        createdAt,
        confirmedAt,
        confirmedBy,
        notes,
      ];
}
