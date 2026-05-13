import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/staff/domain/entities/staff.dart';

class StaffModel extends Staff {
  final Map<String, dynamic>? workingHours;

  const StaffModel({
    required super.id,
    required super.name,
    required super.email,
    super.phoneNumber,
    required super.role,
    required super.clinicId,
    super.createdAt,
    super.updatedAt,
    this.workingHours,
  });

  factory StaffModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StaffModel.fromJson(data).copyWith(id: doc.id);
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    if (json['email'] == null) {
      throw const FormatException("email field is missing");
    }
    return StaffModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      role: json['role'],
      clinicId: json['clinicId'],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      workingHours: json['workingHours'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'clinicId': clinicId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'workingHours': workingHours,
    };
  }

  @override
  StaffModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? clinicId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? workingHours,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      clinicId: clinicId ?? this.clinicId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workingHours: workingHours ?? this.workingHours,
    );
  }
}
