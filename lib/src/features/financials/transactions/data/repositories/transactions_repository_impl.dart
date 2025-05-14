import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/transactions/data/remote/transactions_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/repositories/abstract_financials_repository.dart';

class TransactionsRepositoryImpl extends AbstractTransactionsRepository {
  final TransactionsFirebaseApi firebaseApi;

  TransactionsRepositoryImpl(this.firebaseApi);

  /// Gets a list of transactions.
  @override
  Future<Either<Failure, List<TransactionModel>>> getTransactions(
      {String? lastDocumentId, int limit = 20}) {
    return firebaseApi.getTransactions(
        lastDocumentId: lastDocumentId, limit: limit);
  }

  /// Adds a new transaction.
  @override
  Future<Either<Failure, TransactionModel>> addTransaction(
      TransactionModel transactionModel) {
    return firebaseApi.addTransaction(transactionModel);
  }

  /// Updates an existing transaction.
  @override
  Future<Either<Failure, TransactionModel>> updateTransaction(
      String id, TransactionModel transactionModel) {
    return firebaseApi.updateTransaction(id, transactionModel);
  }

  /// Deletes a transaction by its ID.
  @override
  Future<Either<Failure, void>> deleteTransaction(String id) {
    return firebaseApi.deleteTransaction(id);
  }

  /// Searches transactions based on criteria.
  @override
  Future<Either<Failure, List<TransactionModel>>> searchTransactions(
      {String? description}) {
    return firebaseApi.searchTransactions(description: description);
  }

  /// Gets transactions by a specific date.
  @override
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(
      DateTime date,
      {String? lastDocumentID,
      int limit = 20}) {
    return firebaseApi.getTransactionsByDate(date, limit: limit);
  }

  /// Returns the count of transactions as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getTransactionsCount() {
    return firebaseApi.getTransactionsCount();
  }

  /// Returns the total revenue (inwards) for a given year.
  @override
  Future<Either<Failure, double>> getTotalRevenueForYear(int year) {
    return firebaseApi.getTotalRevenueForYear(year);
  }

  /// Returns the total expenses (outwards) for a given year.
  @override
  Future<Either<Failure, double>> getTotalExpensesForYear(int year) {
    return firebaseApi.getTotalExpensesForYear(year);
  }

  /// Returns the total revenue (inwards) for a given month and year.
  @override
  Future<Either<Failure, double>> getTotalRevenueForMonth(int year, int month) {
    return firebaseApi.getTotalRevenueForMonth(year, month);
  }

  /// Returns the total expenses (outwards) for a given month and year.
  @override
  Future<Either<Failure, double>> getTotalExpensesForMonth(
      int year, int month) {
    return firebaseApi.getTotalExpensesForMonth(year, month);
  }

  /// Returns the total for a given direction (inwards/outwards) and optional source.
  @override
  Future<Either<Failure, double>> getTotalByDirectionAndSource({
    required TransactionDirection direction,
    TransactionSource? source,
    int? year,
    int? month,
  }) {
    return firebaseApi.getTotalByDirectionAndSource(
      direction: direction,
      source: source,
      year: year,
      month: month,
    );
  }

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
  @override
  Future<Either<Failure, DocumentSnapshot?>> validateAndFetchReferenceId({
    required String referenceId,
    required TransactionSource transactionSource,
  }) {
    return firebaseApi.validateAndFetchReferenceId(
      referenceId: referenceId,
      transactionSource: transactionSource,
    );
  }

  /// Deletes a transaction by its reference ID.
  Future<Either<Failure, void>> deleteTransactionByReferenceId(
      String referenceId) async {
    return firebaseApi.deleteTransactionByReferenceId(referenceId);
      }
}
