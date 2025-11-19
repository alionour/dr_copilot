import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';

class SessionsUseCase {
  final AbstractSessionsRepository repository;

  SessionsUseCase(this.repository);

  /// Gets a list of sessions.
  Future<Either<Failure, List<SessionModel>>> getSessions(
      {String? lastDocumentID, int? limit = 20}) async {
    return await repository.getSessions(
        lastDocumentID: lastDocumentID, limit: limit ?? 20);
  }

  /// Adds a new session.
  Future<Either<Failure, SessionModel>> addSession(
      SessionModel sessionModel) async {
    return await repository.addSession(sessionModel);
  }

  /// Updates an existing session.
  Future<Either<Failure, SessionModel>> updateSession(
      String id, SessionModel sessionModel) async {
    return await repository.updateSession(id, sessionModel);
  }

  /// Deletes a session by their ID.
  Future<Either<Failure, void>> deleteSession(String id) async {
    return await repository.deleteSession(id);
  }

  /// Searches sessions based on criteria.
  Future<Either<Failure, List<SessionModel>>> searchSessions(
      {String? name}) async {
    return await repository.searchSessions(name: name);
  }

  /// Gets sessions by a specific date.
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(
      DateTime date) async {
    return await repository.getSessionsByDate(date);
  }

  /// Detects the type of session based on patient name.
  Future<Either<Failure, SessionType>> detectSessionType(
      String patientId) async {
    return await repository.detectSessionType(patientId);
  }

  /// Gets a single session by its ID.
  Future<Either<Failure, SessionModel>> getSessionById(String id) async {
    return await repository.getSessionById(id);
  }

  /// Gets all sessions without pagination.
  Future<Either<Failure, List<SessionModel>>> getAllSessions() async {
    return await repository.getAllSessions();
  }

  /// Returns the count of sessions as an [int] or a [Failure] in case of an error.
  Future<Either<Failure, int>> getSessionsCount() async {
    return await repository.getSessionsCount();
  }

  /// Returns the count of sessions for a specific month and year.
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) async {
    return await repository.getSessionsCountForMonth(year: year, month: month);
  }

  /// Returns the count of sessions for a specific year.
  Future<Either<Failure, int>> getSessionsCountForYear(
      {required int year}) async {
    return await repository.getSessionsCountForYear(year: year);
  }

  /// Sums the total price of all sessions in a specific month for the authenticated user.
  Future<Either<Failure, double>> sumSessionCostsForMonth(
      {required int year, required int month}) async {
    return await repository.sumSessionCostsForMonth(year: year, month: month);
  }

  /// Sums the total price of all sessions in a specific year for the authenticated user.
  Future<Either<Failure, double>> sumSessionCostsForYear(
      {required int year}) async {
    return await repository.sumSessionCostsForYear(year: year);
  }

  /// Sums the total price of all sessions for the authenticated user (all time).
  Future<Either<Failure, double>> sumAllSessionCostsForUser() async {
    return await repository.sumAllSessionCostsForUser();
  }
}
