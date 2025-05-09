import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';

/// Abstract repository for financial transactions.
abstract class AbstractTransactionsRepository {
  /// Fetches all transactions.
  Future<Either<Failure, List<TransactionModel>>> getTransactions({
    String? lastDocumentId,
    int limit = 20,
  });

  /// Adds a new transaction.
  Future<Either<Failure, TransactionModel>> addTransaction(
      TransactionModel transactionModel);

  /// Updates an existing transaction.
  Future<Either<Failure, TransactionModel>> updateTransaction(
      String id, TransactionModel transactionModel);

  /// Deletes a transaction by its ID.
  Future<Either<Failure, void>> deleteTransaction(String id);

  /// Returns the count of transactions as an [int] or a [Failure] in case of an error.
  Future<Either<Failure, int>> getTransactionsCount();

  /// Searches transactions based on criteria.
  Future<Either<Failure, List<TransactionModel>>> searchTransactions({
    String? description,
  });

  /// Gets transactions by a specific date.
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(
      DateTime date,
      {String? lastDocumentID,
      int limit = 20});

  /// Returns the total revenue (inwards) for a given year.
  Future<Either<Failure, double>> getTotalRevenueForYear(int year);

  /// Returns the total expenses (outwards) for a given year.
  Future<Either<Failure, double>> getTotalExpensesForYear(int year);

  /// Returns the total revenue (inwards) for a given month and year.
  Future<Either<Failure, double>> getTotalRevenueForMonth(int year, int month);

  /// Returns the total expenses (outwards) for a given month and year.
  Future<Either<Failure, double>> getTotalExpensesForMonth(int year, int month);

  /// Returns the total for a given direction (inwards/outwards) and optional source.
  Future<Either<Failure, double>> getTotalByDirectionAndSource({
    required TransactionDirection direction,
    TransactionSource? source,
    int? year,
    int? month,
  });
}
