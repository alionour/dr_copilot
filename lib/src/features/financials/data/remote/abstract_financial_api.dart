import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// An abstract class that defines the API for financial-related operations.
abstract class AbstractFinancialApi {
  /// Fetches a list of financials.
  Future<List<TransactionModel>> fetchFinancials();

  /// Adds a new financial.
  Future<TransactionModel> addFinancial(TransactionModel financial);

  /// Updates an existing financial.
  Future<TransactionModel> updateFinancial(TransactionModel financial);

  /// Deletes a financial by their ID.
  Future<void> deleteFinancial(String financialId);

  /// Adds a new currency profile for the user.
  Future<Either<Failure, CurrencyProfileModel>> addCurrencyProfile({
    required CurrencyProfileModel currencyProfile,
  });

  /// Fetches all currency profiles for the user.
  Future<Either<Failure, List<CurrencyProfileModel>>> fetchCurrencyProfiles();

  /// Deletes a currency profile by its document ID.
  Future<Either<Failure, void>> deleteCurrencyProfile(String id);

  /// Updates an existing currency profile.
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

  /// Gets the count of sessions for a specific month and year.
  Future<Either<Failure, int>> getSessionsCountForMonth({
    required int year,
    required int month,
  });

  /// Gets the count of sessions for a specific year.
  Future<Either<Failure, int>> getSessionsCountForYear({
    required int year,
  });

  /// Gets the count of evaluations.
  Future<Either<Failure, int>> getEvaluationsCount();

  /// Gets the count of evaluations for a specific month and year.
  Future<Either<Failure, int>> getEvaluationsCountForMonth({
    required int year,
    required int month,
  });

  /// Gets the count of evaluations for a specific year.
  Future<Either<Failure, int>> getEvaluationsCountForYear({
    required int year,
  });
}
