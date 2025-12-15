import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';

abstract class InvitationRepository {
  Future<Either<Failure, void>> createInvitation(InvitationModel invitation);
  Future<Either<Failure, List<InvitationModel>>> getInvitationsByClinic(
      String clinicId);
  Future<Either<Failure, List<InvitationModel>>> getPendingInvitationsByClinic(
      String clinicId);
  Future<Either<Failure, void>> deleteInvitation(String invitationId);
  Future<Either<Failure, void>> resendInvitation(String invitationId);
}

