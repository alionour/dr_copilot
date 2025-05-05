import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';

/// Abstract repository for financial transactions.
abstract class AbstractFinancialsRepository {
  /// Returns the number of sessions for the specified [year].
  ///
  /// Throws a [Failure] if the operation fails.
  ///
  /// [year]: The year for which to count the sessions.
  ///
  /// Returns an [Either] containing a [Failure] on error, or an [int] representing the session count on success.
  Future<Either<Failure, int>> getSessionsCountForYear({required int year});

  /// Returns the number of sessions for a specific month and year.
  ///
  /// [year] - The year for which to retrieve the session count.
  /// [month] - The month for which to retrieve the session count.
  /// Returns a [Future] containing either a [Failure] or the session count as [int].
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month});

  /// Returns the number of evaluations for a specific year.
  ///
  /// [year] - The year for which to retrieve the evaluation count.
  /// Returns a [Future] containing either a [Failure] or the evaluation count as [int].
  Future<Either<Failure, int>> getEvaluationsCountForYear({required int year});

  /// Returns the number of evaluations for a specific month and year.
  ///
  /// [year] - The year for which to retrieve the evaluation count.
  /// [month] - The month for which to retrieve the evaluation count.
  /// Returns a [Future] containing either a [Failure] or the evaluation count as [int].
  Future<Either<Failure, int>> getEvaluationsCountForMonth(
      {required int year, required int month});

  /// Fetches all currency profiles for the current user.
  Future<Either<Failure, List<CurrencyProfileModel>>> fetchCurrencyProfiles();

  /// Adds a new currency profile for the current user.
  Future<Either<Failure, CurrencyProfileModel>> addCurrencyProfile({
    required CurrencyProfileModel currencyProfile,
  });

  /// Deletes a currency profile by its document ID for the current user.
  Future<Either<Failure, void>> deleteCurrencyProfile(String id);

  /// Updates an existing currency profile for the current user.
  Future<Either<Failure, CurrencyProfileModel>> updateCurrencyProfile(
      CurrencyProfileModel profile);

  /// Gets the sum of session costs for a given month and year.
  Future<Either<Failure, double>> getSessionsSumForMonth({
    required int year,
    required int month,
  });

  /// Gets the sum of session costs for a given year.
  Future<Either<Failure, double>> getSessionsSumForYear({
    required int year,
  });

  /// Gets the sum of evaluation costs for a given month and year.
  Future<Either<Failure, double>> getEvaluationsSumForMonth({
    required int year,
    required int month,
  });

  /// Gets the sum of evaluation costs for a given year.
  Future<Either<Failure, double>> getEvaluationsSumForYear({
    required int year,
  });

  /// Gets the count of sessions.
  Future<Either<Failure, int>> getSessionsCount();

  /// Gets the count of evaluations.
  Future<Either<Failure, int>> getEvaluationsCount();
}
