import 'package:dartz/dartz.dart';
import '../models/transaction_model.dart';
import '../../../../core/error/failures.dart';

/// Abstract repository for financial transactions.
abstract class AbstractFinancialsRepository {
  /// Fetches all transactions. 
  Future<Either<Failure, List<TransactionModel>>> getTransactions({
    String? lastDocumentID,
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


  /// Searches transactions based on criteria.
  Future<Either<Failure, List<TransactionModel>>> searchTransactions({
    String? description,
  });

  /// Gets transactions by a specific date.
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(DateTime date,
      {String? lastDocumentID, int limit = 20});
}
