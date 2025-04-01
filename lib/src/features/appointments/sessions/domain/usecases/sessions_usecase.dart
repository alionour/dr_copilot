import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';

class SessionsUseCase {
  final AbstractSessionsRepository repository;

  SessionsUseCase(this.repository);

  /// Gets a list of sessions.
  Future<Either<Failure, List<SessionModel>>> getSessions(String query) async {
    return await repository.getSessions(query);
  }

  /// Adds a new session.
  Future<Either<Failure, SessionModel>> addSession(
      SessionModel sessionModel) async {
    return await repository.addSession(sessionModel);
  }

  /// Updates an existing session.
  Future<Either<Failure, SessionModel>> updateSession(String id,
      SessionModel sessionModel) async {
    return await repository.updateSession(id,sessionModel);
  }

  /// Deletes a session by their ID.
  Future<Either<Failure, SessionModel>> deleteSession(String id) async {
    return await repository.deleteSession(id);
  }

  /// Searches sessions based on criteria.
  Future<Either<Failure, List<SessionModel>>> searchSessions(
      String query) async {
    return await repository.searchSessions(query);
  }
}
