import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';

abstract class InvitationEvent extends Equatable {
  const InvitationEvent();

  @override
  List<Object?> get props => [];
}

class LoadInvitations extends InvitationEvent {
  final String clinicId;

  const LoadInvitations(this.clinicId);

  @override
  List<Object?> get props => [clinicId];
}

class LoadPendingInvitations extends InvitationEvent {
  final String clinicId;

  const LoadPendingInvitations(this.clinicId);

  @override
  List<Object?> get props => [clinicId];
}

class CreateInvitation extends InvitationEvent {
  final InvitationModel invitation;

  const CreateInvitation(this.invitation);

  @override
  List<Object?> get props => [invitation];
}

class DeleteInvitation extends InvitationEvent {
  final String invitationId;

  const DeleteInvitation(this.invitationId);

  @override
  List<Object?> get props => [invitationId];
}

class ResendInvitation extends InvitationEvent {
  final String invitationId;

  const ResendInvitation(this.invitationId);

  @override
  List<Object?> get props => [invitationId];
}

class LoadInvitationsForEmail extends InvitationEvent {
  final String email;

  const LoadInvitationsForEmail(this.email);

  @override
  List<Object?> get props => [email];
}
