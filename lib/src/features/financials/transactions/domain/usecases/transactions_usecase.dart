import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import '../repositories/abstract_financials_repository.dart';

/// Use case for managing financial transactions.
class TransactionsUseCase {
  final AbstractTransactionsRepository repository;

  /// Constructor for [TransactionsUseCase].
  TransactionsUseCase(this.repository);

  /// Fetches all transactions.
  Future<Either<Failure, List<TransactionModel>>> getTransactions({
    String? lastDocumentId, // Corrected parameter name
    int? limit = 20,
  }) {
    return repository.getTransactions(
      lastDocumentId: lastDocumentId,
      limit: limit ?? 20,
    );
  }

  /// Adds a new transaction.
  Future<Either<Failure, void>> addTransaction(TransactionModel transaction) {
    return repository.addTransaction(transaction);
  }

  /// Updates an existing transaction.
  Future<Either<Failure, TransactionModel>> updateTransaction(
      String id, TransactionModel transactionModel) async {
    return await repository.updateTransaction(id, transactionModel);
  }

  /// Deletes a transaction by its ID.
  Future<Either<Failure, void>> deleteTransaction(String id) {
    return repository.deleteTransaction(id);
  }

  /// Searches transactions based on criteria.
  Future<Either<Failure, List<TransactionModel>>> searchTransactions(
      {String? description}) async {
    return await repository.searchTransactions(description: description);
  }

  /// Gets transactions by a specific date.
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(
      DateTime date,
      {String? lastDocumentID,
      int limit = 20}) async {
    return await repository.getTransactionsByDate(date,
        lastDocumentID: lastDocumentID, limit: limit);
  }

  /// Returns the count of transactions as an [int] or a [Failure] in case of an error.
  Future<Either<Failure, int>> getTransactionsCount() async {
    return await repository.getTransactionsCount();
  }
}
