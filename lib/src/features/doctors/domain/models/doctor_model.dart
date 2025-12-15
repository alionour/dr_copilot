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

