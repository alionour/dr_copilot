
import 'package:dr_copilot/src/features/financials/domain/models/bill_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';

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

  // --- Transaction CRUD ---
  /// Adds a new transaction for the user.
  Future<Either<Failure, void>> addTransaction({required TransactionModel transaction});

  /// Updates an existing transaction for the user.
  Future<Either<Failure, TransactionModel>> updateTransaction({required TransactionModel transaction});

  /// Deletes a transaction by its document ID.
  Future<Either<Failure, void>> deleteTransaction(String id);

  /// Fetches all transactions for the user.
  Future<Either<Failure, List<TransactionModel>>> fetchTransactions();

  // --- Bill CRUD ---
  /// Adds a new bill for the user.
  Future<Either<Failure, BillModel>> addBill({required BillModel bill});

  /// Updates an existing bill for the user.
  Future<Either<Failure, BillModel>> updateBill({required BillModel bill});

  /// Fetches all bills for the user.
  Future<Either<Failure, List<BillModel>>> fetchBills();

  /// Deletes a bill by its document ID.
  Future<Either<Failure, void>> deleteBill(String id);

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

  /// Adds a new goal for the user.
  Future<Either<Failure, GoalModelBase>> addGoal({
    required GoalModelBase goal,
  });

  /// Updates an existing goal for the user.
  Future<Either<Failure, GoalModelBase>> updateGoal({
    required GoalModelBase goal,
  });

  /// Fetches all goals for the user.
  Future<Either<Failure, List<GoalModelBase>>> fetchGoals();

  /// Deletes a goal by its document ID.
  Future<Either<Failure, void>> deleteGoal(String id);

  /// Adds a new scheduled bill for the user.
  Future<Either<Failure, ScheduledBillModel>> addScheduledBill({
    required ScheduledBillModel scheduledBill,
  });

  /// Updates an existing scheduled bill for the user.
  Future<Either<Failure, ScheduledBillModel>> updateScheduledBill({
    required ScheduledBillModel scheduledBill,
  });

  /// Fetches all scheduled bills for the user.
  Future<Either<Failure, List<ScheduledBillModel>>> fetchScheduledBills();

  /// Deletes a scheduled bill by its document ID.
  Future<Either<Failure, void>> deleteScheduledBill(String id);
}
