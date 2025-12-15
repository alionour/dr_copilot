import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/teams/domain/models/custom_team_model.dart';

abstract class AbstractCustomTeamsRepository {
  Future<Either<Failure, void>> createTeam(CustomTeamModel team);
  Future<Either<Failure, void>> updateTeam(CustomTeamModel team);
  Future<Either<Failure, void>> archiveTeam(String teamId);
  Future<Either<Failure, void>> unarchiveTeam(String teamId);
  Future<Either<Failure, List<CustomTeamModel>>> getTeamsForClinic(
    String clinicId,
  );
  Future<Either<Failure, List<CustomTeamModel>>> getMyTeams(String ownerId);
  Stream<Either<Failure, List<CustomTeamModel>>> watchTeamsForClinic(
    String clinicId,
  );
}

