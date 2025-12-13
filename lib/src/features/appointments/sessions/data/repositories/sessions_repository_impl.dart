import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';

class SessionsRepositoryImpl extends AbstractSessionsRepository {
  final SessionsFirebaseApi firebaseApi;

  SessionsRepositoryImpl(this.firebaseApi);

  /// Gets a list of sessions.
  @override
  Future<Either<Failure, List<SessionModel>>> getSessions({
    String? lastDocumentID,
    int limit = 20,
  }) {
    return firebaseApi.getSessions(
      lastDocumentID: lastDocumentID,
      limit: limit,
    );
  }

  /// Adds a new session.
  @override
  Future<Either<Failure, SessionModel>> addSession(SessionModel sessionModel) {
    return firebaseApi.addSession(sessionModel);
  }

  /// Updates an existing session.
  @override
  Future<Either<Failure, SessionModel>> updateSession(
    String id,
    SessionModel sessionModel,
  ) {
    return firebaseApi.updateSession(id, sessionModel);
  }

  /// Deletes a session by their ID.
  @override
  Future<Either<Failure, void>> deleteSession(String id) {
    return firebaseApi.deleteSession(id);
  }

  /// Gets a list of deleted sessions.
  @override
  Future<Either<Failure, List<SessionModel>>> getDeletedSessions() {
    return firebaseApi.getDeletedSessions();
  }

  /// Restores a deleted session.
  @override
  Future<Either<Failure, void>> restoreSession(String id) {
    return firebaseApi.restoreSession(id);
  }

  /// Permanently deletes a session.
  @override
  Future<Either<Failure, void>> permanentlyDeleteSession(String id) {
    return firebaseApi.permanentlyDeleteSession(id);
  }

  /// Searches sessions based on criteria.
  @override
  Future<Either<Failure, List<SessionModel>>> searchSessions({
    String? name,
    String? lastDocumentID,
    int limit = 20,
  }) {
    return firebaseApi.searchSessions(
      name: name,
      lastDocumentID: lastDocumentID,
      limit: limit,
    );
  }

  /// Gets sessions by a specific date.
  @override
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(DateTime date) {
    return firebaseApi.getSessionsByDate(date);
  }

  /// Gets a single session by its ID.
  @override
  Future<Either<Failure, SessionModel>> getSessionById(String id) {
    return firebaseApi.getSessionById(id);
  }

  /// Gets all sessions without pagination.
  @override
  Future<Either<Failure, List<SessionModel>>> getAllSessions() {
    return firebaseApi.getAllSessions();
  }

  /// Detects the type of session based on patient ID.

  @override
  Future<Either<Failure, String>> detectSessionType(String patientId) {
    return firebaseApi.detectSessionType(patientId);
  }

  /// Returns the count of sessions as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getSessionsCount() {
    return firebaseApi.getSessionsCount();
  }

  /// Returns the count of sessions for a specific month and year.
  @override
  Future<Either<Failure, int>> getSessionsCountForMonth({
    required int year,
    required int month,
  }) {
    return firebaseApi.getSessionsCountForMonth(year: year, month: month);
  }

  /// Returns the count of sessions for a specific year.
  @override
  Future<Either<Failure, int>> getSessionsCountForYear({required int year}) {
    return firebaseApi.getSessionsCountForYear(year: year);
  }

  /// Sums the total price of all sessions in a specific month for the authenticated user.
  @override
  Future<Either<Failure, double>> sumSessionCostsForMonth({
    required int year,
    required int month,
  }) {
    return firebaseApi.sumSessionCostsForMonth(year: year, month: month);
  }

  /// Sums the total price of all sessions in a specific year for the authenticated user.
  @override
  Future<Either<Failure, double>> sumSessionCostsForYear({required int year}) {
    return firebaseApi.sumSessionCostsForYear(year: year);
  }

  /// Sums the total price of all sessions for the authenticated user (all time).
  @override
  Future<Either<Failure, double>> sumAllSessionCostsForUser() {
    return firebaseApi.sumAllSessionCostsForUser();
  }
}
