import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';
import 'package:dr_copilot/src/features/invitations/domain/repositories/invitation_repository.dart';

class InvitationUseCases {
  final InvitationRepository _repository;

  InvitationUseCases(this._repository);

  Future<Either<Failure, void>> createInvitation(
      InvitationModel invitation) async {
    return await _repository.createInvitation(invitation);
  }

  Future<Either<Failure, List<InvitationModel>>> getInvitationsByClinic(
      String clinicId) async {
    return await _repository.getInvitationsByClinic(clinicId);
  }

  Future<Either<Failure, List<InvitationModel>>> getPendingInvitationsByClinic(
      String clinicId) async {
    return await _repository.getPendingInvitationsByClinic(clinicId);
  }

  Future<Either<Failure, void>> deleteInvitation(String invitationId) async {
    return await _repository.deleteInvitation(invitationId);
  }

  Future<Either<Failure, void>> resendInvitation(String invitationId) async {
    return await _repository.resendInvitation(invitationId);
  }
}

