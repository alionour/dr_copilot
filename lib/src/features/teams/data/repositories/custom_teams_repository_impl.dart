import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/teams/domain/models/custom_team_model.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';

class CustomTeamsRepositoryImpl implements AbstractCustomTeamsRepository {
  final FirebaseFirestore _firestore;

  CustomTeamsRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _teamsCollection =>
      _firestore.collection('custom_teams');

  @override
  Future<Either<Failure, void>> createTeam(CustomTeamModel team) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Set the team document
        transaction.set(_teamsCollection.doc(team.id), team.toJson());

        // Set the corresponding team conversation document to match
        final conversationRef = _firestore.collection('team_conversations').doc(team.id);
        transaction.set(conversationRef, {
          'clinicId': team.clinicId,
          'participantIds': team.memberIds,
          'createdAt': Timestamp.fromDate(team.createdAt),
          'updatedAt': Timestamp.fromDate(team.createdAt),
          'metadata': {
            'teamId': team.id,
            'teamName': team.name,
          },
        });
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> updateTeam(CustomTeamModel team) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Update the team document
        transaction.update(_teamsCollection.doc(team.id), team.toJson());

        // Update/merge the corresponding team conversation document
        final conversationRef = _firestore.collection('team_conversations').doc(team.id);
        transaction.set(
          conversationRef,
          {
            'clinicId': team.clinicId,
            'participantIds': team.memberIds,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
            'metadata': {
              'teamId': team.id,
              'teamName': team.name,
            },
          },
          SetOptions(merge: true),
        );
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, List<CustomTeamModel>>> getTeamsForClinic(
    String clinicId,
  ) async {
    try {
      final snapshot = await _teamsCollection
          .where('clinicId', isEqualTo: clinicId)
          .get();

      final teams = snapshot.docs
          .map((doc) => CustomTeamModel.fromFirestore(doc))
          .toList();

      return Right(teams);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, List<CustomTeamModel>>> getMyTeams(
    String ownerId,
  ) async {
    try {
      final snapshot = await _teamsCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();

      final teams = snapshot.docs
          .map((doc) => CustomTeamModel.fromFirestore(doc))
          .toList();

      return Right(teams);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Stream<Either<Failure, List<CustomTeamModel>>> watchTeamsForClinic(
    String clinicId,
  ) {
    return _teamsCollection
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snapshot) {
          try {
            final teams = snapshot.docs
                .map((doc) => CustomTeamModel.fromFirestore(doc))
                .toList();
            return Right(teams);
          } catch (e) {
            return Left(ServerFailure(e.toString(), 500));
          }
        });
  }

  @override
  Future<Either<Failure, void>> archiveTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).update({'isArchived': true});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> unarchiveTeam(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).update({'isArchived': false});
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}

