/// An abstract class that defines the contract for session-related operations.
///
/// This repository provides methods for managing sessions, including:
/// - Retrieving a paginated list of sessions.
/// - Adding, updating, and deleting sessions.
/// - Searching sessions by patient ID or date.
/// - Detecting the session type for a given patient.
/// - Getting the total count of sessions.
///
/// All methods return an [Either] type from the `dartz` package, encapsulating
/// either a [Failure] or the expected result, to handle errors gracefully.

library abstract_sessions_repository;

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
  Future<Either<Failure, List<SessionModel>>> searchSessions(
      {String? patientId});

  /// Gets sessions by a specific date.
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(DateTime date);

  /// Detects the type of session based on patient ID.
  Future<Either<Failure, SessionType>> detectSessionType(String patientId);

  /// Returns the count of sessions as an [int] or a [Failure] in case of an error.
  Future<Either<Failure, int>> getSessionsCount();
}
