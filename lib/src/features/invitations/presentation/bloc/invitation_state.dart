import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';

abstract class InvitationState extends Equatable {
  const InvitationState();

  @override
  List<Object?> get props => [];
}

class InvitationInitial extends InvitationState {}

class InvitationLoading extends InvitationState {}

class InvitationLoaded extends InvitationState {
  final List<InvitationModel> invitations;

  const InvitationLoaded(this.invitations);

  @override
  List<Object?> get props => [invitations];
}

class InvitationOperationSuccess extends InvitationState {
  final String message;

  const InvitationOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class InvitationError extends InvitationState {
  final String message;

  const InvitationError(this.message);

  @override
  List<Object?> get props => [message];
}
