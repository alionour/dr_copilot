import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DoctorModel extends Equatable {
  final String id;
  final String name;
  final String specialty;
  final String clinicId;
  final String email;
  final String phoneNumber;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final Map<String, dynamic>? workingHours;
  final int? appointmentDuration;
  final double? consultationPrice;
  final bool isAvailableForBooking;
  final String? currencyProfileId;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinicId,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.workingHours,
    this.appointmentDuration,
    this.consultationPrice,
    this.isAvailableForBooking = true,
    this.currencyProfileId,
  });

  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? clinicId,
    String? email,
    String? phoneNumber,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Map<String, dynamic>? workingHours,
    int? appointmentDuration,
    double? consultationPrice,
    bool? isAvailableForBooking,
    String? currencyProfileId,
  }) {
    return DoctorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      clinicId: clinicId ?? this.clinicId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workingHours: workingHours ?? this.workingHours,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      consultationPrice: consultationPrice ?? this.consultationPrice,
      isAvailableForBooking:
          isAvailableForBooking ?? this.isAvailableForBooking,
      currencyProfileId: currencyProfileId ?? this.currencyProfileId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'clinicId': clinicId,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'workingHours': workingHours,
      'appointmentDuration': appointmentDuration,
      'consultationPrice': consultationPrice,
      'isAvailableForBooking': isAvailableForBooking,
      'currencyProfileId': currencyProfileId,
    };
  }

  factory DoctorModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DoctorModel(
      id: doc.id,
      name: data['name'] as String,
      specialty: data['specialty'] as String,
      clinicId: data['clinicId'] as String,
      email: data['email'] as String,
      phoneNumber: data['phoneNumber'] as String,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
      workingHours: data['workingHours'] as Map<String, dynamic>?,
      appointmentDuration: data['appointmentDuration'] as int?,
      consultationPrice: (data['consultationPrice'] as num?)?.toDouble(),
      isAvailableForBooking: data['isAvailableForBooking'] as bool? ?? true,
      currencyProfileId: data['currencyProfileId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        specialty,
        clinicId,
        email,
        phoneNumber,
        createdAt,
        updatedAt,
        workingHours,
        appointmentDuration,
        consultationPrice,
        isAvailableForBooking,
        currencyProfileId,
      ];
}
