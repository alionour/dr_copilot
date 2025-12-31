import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A model class representing a doctor in the system.
class DoctorModel extends Equatable {
  /// The unique identifier of the doctor.
  final String id;

  /// The full name of the doctor.
  final String name;

  /// The medical specialty of the doctor.
  final String specialty;

  /// The ID of the clinic the doctor belongs to.
  final String clinicId;

  /// The email address of the doctor.
  final String email;

  /// The phone number of the doctor.
  final String phoneNumber;

  /// The timestamp when the doctor record was created.
  final Timestamp createdAt;

  /// The timestamp when the doctor record was last updated.
  final Timestamp updatedAt;

  /// Creates a new [DoctorModel] instance.
  const DoctorModel({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinicId,
    required this.email,
    required this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this [DoctorModel] with the given fields replaced with new values.
  DoctorModel copyWith({
    String? id,
    String? name,
    String? specialty,
    String? clinicId,
    String? email,
    String? phoneNumber,
    Timestamp? createdAt,
    Timestamp? updatedAt,
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
    );
  }

  /// Converts the [DoctorModel] to a JSON map.
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
    };
  }

  /// Creates a [DoctorModel] from a Firestore [DocumentSnapshot].
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
      ];
}
