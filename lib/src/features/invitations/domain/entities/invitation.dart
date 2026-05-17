import 'package:equatable/equatable.dart';

class Invitation extends Equatable {
  final String id;
  final String email;
  final String clinicId;
  final String invitedBy;
  final List<String> roles;
  final List<String> permissions;
  final List<String> linkedDoctorIds;
  final List<String> departmentIds;
  final List<String> teamIds;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const Invitation({
    required this.id,
    required this.email,
    required this.clinicId,
    required this.invitedBy,
    required this.roles,
    required this.permissions,
    this.linkedDoctorIds = const [],
    this.departmentIds = const [],
    this.teamIds = const [],
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        clinicId,
        invitedBy,
        roles,
        permissions,
        linkedDoctorIds,
        departmentIds,
        teamIds,
        status,
        createdAt,
        acceptedAt,
      ];
}
