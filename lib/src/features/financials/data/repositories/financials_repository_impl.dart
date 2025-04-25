import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/data/remote/financials_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/domain/repositories/abstract_financials_repository.dart';

class FinancialsRepositoryImpl extends AbstractFinancialsRepository {
  final FinancialsFirebaseApi firebaseApi;

  FinancialsRepositoryImpl(this.firebaseApi);

  /// Gets a list of transactions.
  @override
  Future<Either<Failure, List<TransactionModel>>> getTransactions(
      {String? lastDocumentID, int limit = 20}) {
    return firebaseApi.getTransactions(
        lastDocumentID: lastDocumentID, limit: limit);
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
    return firebaseApi.getTransactionsByDate(date,
         limit: limit);
  }
}
