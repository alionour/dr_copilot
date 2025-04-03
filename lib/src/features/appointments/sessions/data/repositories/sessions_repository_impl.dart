import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';

class SessionsRepositoryImpl extends AbstractSessionsRepository {
  final SessionFirebaseApi firebaseApi;

  SessionsRepositoryImpl({required this.firebaseApi});

  /// Gets a list of sessions.
  @override
  Future<Either<Failure, List<SessionModel>>> getSessions(
      {String? lastDocumentID, int limit = 20}) {
    return firebaseApi.getSessions(
        lastDocumentID: lastDocumentID, limit: limit);
  }

  /// Adds a new session.
  @override
  Future<Either<Failure, SessionModel>> addSession(SessionModel sessionModel) {
    return firebaseApi.addSession(sessionModel);
  }

  /// Updates an existing session.
  @override
  Future<Either<Failure, SessionModel>> updateSession(
      String id, SessionModel sessionModel) {
    return firebaseApi.updateSession(id, sessionModel);
  }

  /// Deletes a session by their ID.
  @override
  Future<Either<Failure, SessionModel>> deleteSession(String id) {
    return firebaseApi.deleteSession(id);
  }

  /// Searches sessions based on criteria.
  @override
  Future<Either<Failure, List<SessionModel>>> searchSessions(String query) {
    return firebaseApi.searchSessions(query);
  }

  /// Gets sessions by a specific date.
  @override
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(DateTime date) {
    return firebaseApi.getSessionsByDate(date);
  }
}
