import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';

// An abstract class that defines the repository for session-related operations.
abstract class AbstractSessionsRepository {
  /// Gets a list of sessions.
  Future<Either<Failure, List<SessionModel>>> getSessions(
      {String? lastDocumentID, int limit = 20});

  /// Adds a new session.
  Future<Either<Failure, SessionModel>> addSession(SessionModel sessionModel);

  /// Updates an existing session.
  Future<Either<Failure, SessionModel>> updateSession(
      String id, SessionModel sessionModel);

  /// Deletes a session by their ID.
  Future<Either<Failure, SessionModel>> deleteSession(String id);

  /// Searches sessions based on criteria.
  Future<Either<Failure, List<SessionModel>>> searchSessions({String? name});

  /// Gets sessions by a specific date.
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(DateTime date);
}
