import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';

/// An abstract class that defines the API for transaction-related operations.
abstract class AbstractTransactionApi {
  /// Adds a new transaction.
  Future<TransactionModel> addTransaction(TransactionModel financial);

  /// Fetches a list of transactions.
  Future<List<TransactionModel>> fetchTransactions();

  /// Deletes a transaction by its ID.
  Future<void> deleteTransaction(String transactionId);

  /// Updates an existing transaction.
  Future<TransactionModel> updateTransaction(TransactionModel transaction);

  /// Searches transactions based on criteria.
  Future<List<TransactionModel>> searchTransactions(String query);

  /// Aggregates and returns the total revenue for a given year.
  Future<double> getTotalRevenueForYear(int year);

  /// Aggregates and returns the total expenses for a given year.
  Future<double> getTotalExpensesForYear(int year);

  /// Aggregates and returns the total revenue for a given year and month.
  Future<double> getTotalRevenueForMonth(int year, int month);

  /// Aggregates and returns the total expenses for a given year and month.
  Future<double> getTotalExpensesForMonth(int year, int month);
}
