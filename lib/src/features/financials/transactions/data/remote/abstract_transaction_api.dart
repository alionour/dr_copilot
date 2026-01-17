import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
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

  /// Validates the provided reference ID and fetches the corresponding
  /// document snapshot from the remote data source.
  ///
  /// This method checks if the given [referenceId] is valid and attempts
  /// to retrieve the associated document. If the operation is successful,
  /// it returns a [DocumentSnapshot] wrapped in a [Right]. If there is a
  /// failure, it returns a [Failure] wrapped in a [Left].
  ///
  /// - Parameters:
  ///   - referenceId: The unique identifier of the reference to validate
  ///     and fetch.
  ///
  /// - Returns: A [Future] containing an [Either] with a [Failure] on the
  ///   left side if an error occurs, or a [DocumentSnapshot?] on the right
  ///   side if the operation is successful.
  Future<Either<Failure, DocumentSnapshot?>> validateAndFetchReferenceId({
    required String referenceId,
    required TransactionSource transactionSource,
  });

  /// Deletes a transaction by its reference ID.
  Future<Either<Failure, void>> deleteTransactionByReferenceId(
      String referenceId);
}

