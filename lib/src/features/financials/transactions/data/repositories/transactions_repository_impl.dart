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
  Future<Either<Failure, List<TransactionModel>>> getTransactions({
    required String clinicId,
    String? lastDocumentId,
    int limit = 20,
  }) {
    return firebaseApi.getTransactions(
      clinicId: clinicId,
      lastDocumentId: lastDocumentId,
      limit: limit,
    );
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
  Future<Either<Failure, List<TransactionModel>>> searchTransactions({
    required String clinicId,
    String? description,
  }) {
    return firebaseApi.searchTransactions(
      clinicId: clinicId,
      description: description,
    );
  }

  /// Gets transactions by a specific date.
  @override
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(
    String clinicId,
    DateTime date, {
    String? lastDocumentID,
    int limit = 20,
  }) {
    return firebaseApi.getTransactionsByDate(
      clinicId,
      date,
      lastDocumentID: lastDocumentID,
      limit: limit,
    );
  }

  /// Returns the count of transactions as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getTransactionsCount(String clinicId) {
    return firebaseApi.getTransactionsCount(clinicId);
  }

  /// Returns the total revenue (inwards) for a given year.
  @override
  Future<Either<Failure, double>> getTotalRevenueForYear(
      String clinicId, int year) {
    return firebaseApi.getTotalRevenueForYear(clinicId, year);
  }

  /// Returns the total expenses (outwards) for a given year.
  @override
  Future<Either<Failure, double>> getTotalExpensesForYear(
      String clinicId, int year) {
    return firebaseApi.getTotalExpensesForYear(clinicId, year);
  }

  /// Returns the total revenue (inwards) for a given month and year.
  @override
  Future<Either<Failure, double>> getTotalRevenueForMonth(
      String clinicId, int year, int month) {
    return firebaseApi.getTotalRevenueForMonth(clinicId, year, month);
  }

  /// Returns the total expenses (outwards) for a given month and year.
  @override
  Future<Either<Failure, double>> getTotalExpensesForMonth(
    String clinicId,
    int year,
    int month,
  ) {
    return firebaseApi.getTotalExpensesForMonth(clinicId, year, month);
  }

  /// Returns the total for a given direction (inwards/outwards) and optional source.
  @override
  Future<Either<Failure, double>> getTotalByDirectionAndSource({
    required String clinicId,
    required TransactionDirection direction,
    TransactionSource? source,
    int? year,
    int? month,
  }) {
    return firebaseApi.getTotalByDirectionAndSource(
      clinicId: clinicId,
      direction: direction,
      source: source,
      year: year,
      month: month,
    );
  }

  /// Validates the provided reference ID and fetches the corresponding
  /// document snapshot from the remote data source.
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
  @override
  Future<Either<Failure, void>> deleteTransactionByReferenceId(
      String clinicId, String referenceId) async {
    return firebaseApi.deleteTransactionByReferenceId(clinicId, referenceId);
  }
}
