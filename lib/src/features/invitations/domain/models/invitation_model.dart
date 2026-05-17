import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/invitations/domain/entities/invitation.dart';

class InvitationModel extends Invitation {
  const InvitationModel({
    required super.id,
    required super.email,
    required super.clinicId,
    required super.clinicName,
    required super.invitedBy,
    required super.roles,
    required super.permissions,
    super.linkedDoctorIds,
    super.departmentIds,
    super.teamIds,
    required super.status,
    required super.createdAt,
    super.acceptedAt,
  });

  factory InvitationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvitationModel(
      id: doc.id,
      email: data['email'] ?? '',
      clinicId: data['clinicId'] ?? '',
      clinicName: data['clinicName'] ?? 'Unknown Clinic',
      invitedBy: data['invitedBy'] ?? '',
      roles: List<String>.from(data['roles'] ?? []),
      permissions: List<String>.from(data['permissions'] ?? []),
      linkedDoctorIds: List<String>.from(data['linkedDoctorIds'] ?? []),
      departmentIds: List<String>.from(data['departmentIds'] ?? []),
      teamIds: List<String>.from(data['teamIds'] ?? []),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      clinicId: json['clinicId'] ?? '',
      clinicName: json['clinicName'] ?? 'Unknown Clinic',
      invitedBy: json['invitedBy'] ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? []),
      linkedDoctorIds: List<String>.from(json['linkedDoctorIds'] ?? []),
      departmentIds: List<String>.from(json['departmentIds'] ?? []),
      teamIds: List<String>.from(json['teamIds'] ?? []),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt']),
      acceptedAt: json['acceptedAt'] != null
          ? (json['acceptedAt'] is Timestamp
              ? (json['acceptedAt'] as Timestamp).toDate()
              : DateTime.parse(json['acceptedAt']))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'clinicId': clinicId,
      'clinicName': clinicName,
      'invitedBy': invitedBy,
      'roles': roles,
      'permissions': permissions,
      'linkedDoctorIds': linkedDoctorIds,
      'departmentIds': departmentIds,
      'teamIds': teamIds,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
    };
  }
}
