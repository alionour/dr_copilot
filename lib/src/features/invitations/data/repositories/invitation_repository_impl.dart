import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/invitations/data/remote/invitation_firebase_api.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';
import 'package:dr_copilot/src/features/invitations/domain/repositories/invitation_repository.dart';

class InvitationRepositoryImpl implements InvitationRepository {
  final InvitationFirebaseApi _api;

  InvitationRepositoryImpl(this._api);

  @override
  Future<Either<Failure, void>> createInvitation(
      InvitationModel invitation) async {
    try {
      await _api.createInvitation(invitation);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<InvitationModel>>> getInvitationsByClinic(
      String clinicId) async {
    try {
      final invitations = await _api.getInvitationsByClinic(clinicId);
      return Right(invitations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<InvitationModel>>> getPendingInvitationsByClinic(
      String clinicId) async {
    try {
      final invitations = await _api.getPendingInvitationsByClinic(clinicId);
      return Right(invitations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvitation(String invitationId) async {
    try {
      await _api.deleteInvitation(invitationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, void>> resendInvitation(String invitationId) async {
    try {
      await _api.resendInvitation(invitationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  @override
  Future<Either<Failure, List<InvitationModel>>> getInvitationsForEmail(
      String email) async {
    try {
      final invitations = await _api.getInvitationsForEmail(email);
      return Right(invitations);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }
}
