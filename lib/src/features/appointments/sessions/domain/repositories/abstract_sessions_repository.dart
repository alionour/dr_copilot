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
  Future<Either<Failure, void>> deleteSession(String id);

  /// Searches sessions based on criteria.
  Future<Either<Failure, List<SessionModel>>> searchSessions({String? name});

  /// Gets sessions by a specific date.
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(DateTime date);

  /// Detects the type of session based on patient ID.
  Future<Either<Failure, SessionType>> detectSessionType(String patientId);

  /// Returns the count of sessions as an [int] or a [Failure] in case of an error.
  Future<Either<Failure, int>> getSessionsCount();

  /// Returns the count of sessions for a specific month and year.
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month});

  /// Returns the count of sessions for a specific year.
  Future<Either<Failure, int>> getSessionsCountForYear({required int year});

  /// Sums the total price of all sessions in a specific month for the authenticated user.
  Future<Either<Failure, double>> sumSessionCostsForMonth(
      {required int year, required int month});

  /// Sums the total price of all sessions in a specific year for the authenticated user.
  Future<Either<Failure, double>> sumSessionCostsForYear({required int year});

  /// Sums the total price of all sessions for the authenticated user (all time).
  Future<Either<Failure, double>> sumAllSessionCostsForUser();
}
