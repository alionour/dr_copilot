import 'package:dartz/dartz.dart';
import '../repositories/abstract_financials_repository.dart';
import '../models/transaction_model.dart';
import '../../../../core/error/failures.dart';

/// Use case for managing financial transactions.
class FinancialsUseCase {
  final AbstractFinancialsRepository repository;

  /// Constructor for [FinancialsUseCase].
  FinancialsUseCase({required this.repository});

  /// Fetches all transactions.
  Future<Either<Failure, List<TransactionModel>>> getTransactions() {
    return repository.getTransactions();
  }

  /// Adds a new transaction.
  Future<Either<Failure, void>> addTransaction(TransactionModel transaction) {
    return repository.addTransaction(transaction);
  }

  /// Deletes a transaction by its ID.
  Future<Either<Failure, void>> deleteTransaction(String id) {
    return repository.deleteTransaction(id);
  }
}
