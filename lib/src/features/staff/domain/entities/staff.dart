
import 'package:equatable/equatable.dart';

class Staff extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String role;
  final String clinicId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Staff({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.role,
    required this.clinicId,
    this.createdAt,
    this.updatedAt,
  });

  Staff copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? clinicId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      clinicId: clinicId ?? this.clinicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, phoneNumber, role, clinicId, createdAt, updatedAt];
}
