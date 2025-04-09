import 'package:dartz/dartz.dart';
import '../models/transaction_model.dart';
import '../../../../core/error/failures.dart';

/// Abstract repository for financial transactions.
abstract class AbstractFinancialsRepository {
  /// Fetches all transactions.
  Future<Either<Failure, List<TransactionModel>>> getTransactions();

  /// Adds a new transaction.
  Future<Either<Failure, void>> addTransaction(TransactionModel transaction);

  /// Deletes a transaction by its ID.
  Future<Either<Failure, void>> deleteTransaction(String id);
}
