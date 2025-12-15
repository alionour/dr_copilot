import 'package:equatable/equatable.dart';

class Invitation extends Equatable {
  final String id;
  final String email;
  final String clinicId;
  final String invitedBy;
  final List<String> roles;
  final List<String> permissions;
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
        status,
        createdAt,
        acceptedAt,
      ];
}

