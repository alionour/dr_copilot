import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/invitations/domain/usecases/invitation_usecases.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_event.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_state.dart';

class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final InvitationUseCases _useCases;

  InvitationBloc(this._useCases) : super(InvitationInitial()) {
    on<LoadInvitations>(_onLoadInvitations);
    on<LoadPendingInvitations>(_onLoadPendingInvitations);
    on<CreateInvitation>(_onCreateInvitation);
    on<DeleteInvitation>(_onDeleteInvitation);
    on<ResendInvitation>(_onResendInvitation);
    on<LoadInvitationsForEmail>(_onLoadInvitationsForEmail);
  }

  Future<void> _onLoadInvitations(
    LoadInvitations event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await _useCases.getInvitationsByClinic(event.clinicId);
    result.fold(
      (failure) => emit(InvitationError(failure.message)),
      (invitations) => emit(InvitationLoaded(invitations)),
    );
  }

  Future<void> _onLoadPendingInvitations(
    LoadPendingInvitations event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result =
        await _useCases.getPendingInvitationsByClinic(event.clinicId);
    result.fold(
      (failure) => emit(InvitationError(failure.message)),
      (invitations) => emit(InvitationLoaded(invitations)),
    );
  }

  Future<void> _onCreateInvitation(
    CreateInvitation event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await _useCases.createInvitation(event.invitation);
    result.fold(
      (failure) => emit(InvitationError(failure.message)),
      (_) => emit(
          const InvitationOperationSuccess('Invitation created successfully')),
    );
  }

  Future<void> _onDeleteInvitation(
    DeleteInvitation event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await _useCases.deleteInvitation(event.invitationId);
    result.fold(
      (failure) => emit(InvitationError(failure.message)),
      (_) => emit(
          const InvitationOperationSuccess('Invitation deleted successfully')),
    );
  }

  Future<void> _onResendInvitation(
    ResendInvitation event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await _useCases.resendInvitation(event.invitationId);
    result.fold(
      (failure) => emit(InvitationError(failure.message)),
      (_) => emit(
          const InvitationOperationSuccess('Invitation resent successfully')),
    );
  }

  Future<void> _onLoadInvitationsForEmail(
    LoadInvitationsForEmail event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoading());
    final result = await _useCases.getInvitationsForEmail(event.email);
    result.fold(
      (failure) => emit(InvitationError(failure.message)),
      (invitations) => emit(InvitationLoaded(invitations)),
    );
  }
}
