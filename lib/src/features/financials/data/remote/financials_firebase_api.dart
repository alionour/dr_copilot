import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/domain/models/transaction_model.dart';

/// Handles Firebase operations for financial transactions.
class FinancialsFirebaseApi {
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('transactions');

  /// Adds a new transaction to Firestore.
  Future<Either<Failure, TransactionModel>> addTransaction(
      TransactionModel transaction) async {
    try {
      await _transactionsCollection
          .doc(transaction.id)
          .set(transaction.toJson());
      return Right(transaction);
    } catch (e) {
            return Left(ServerFailure(e.toString(), 404));

    }
  }

  /// Fetches transactions with optional pagination.
  Future<Either<Failure, List<TransactionModel>>> getTransactions({
    String? lastDocumentID,
    int limit = 20,
  }) async {
    try {
      Query query = _transactionsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentID != null) {
        final lastDocumentSnapshot =
            await _transactionsCollection.doc(lastDocumentID).get();
        query = query.startAfterDocument(lastDocumentSnapshot);
      }

      final querySnapshot = await query.get();
      final transactions = querySnapshot.docs
          .map((doc) =>
              TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return Right(transactions);
    } catch (e) {
            return Left(ServerFailure(e.toString(), 404));

    }
  }

  /// Updates an existing transaction in Firestore.
  Future<Either<Failure, TransactionModel>> updateTransaction(
      String id, TransactionModel transaction) async {
    try {
      await _transactionsCollection.doc(id).update(transaction.toJson());
      return Right(transaction);
    } catch (e) {
            return Left(ServerFailure(e.toString(), 404));

    }
  }

  /// Deletes a transaction by its ID.
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _transactionsCollection.doc(id).delete();
      return const Right(null);
    } catch (e) {
            return Left(ServerFailure(e.toString(), 404));

    }
  }

  /// Searches transactions by description.
  Future<Either<Failure, List<TransactionModel>>> searchTransactions(
      {String? description}) async {
    try {
      Query query = _transactionsCollection;

      if (description != null && description.isNotEmpty) {
        query = query.where('description', isEqualTo: description);
      }

      final querySnapshot = await query.get();
      final transactions = querySnapshot.docs
          .map((doc) =>
              TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return Right(transactions);
    } catch (e) {
            return Left(ServerFailure(e.toString(), 404));

    }
  }

  /// Fetches transactions by a specific date.
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(
      DateTime date) async {
    try {
      final startOfDay =
          Timestamp.fromDate(DateTime(date.year, date.month, date.day));
      final endOfDay = Timestamp.fromDate(
          DateTime(date.year, date.month, date.day, 23, 59, 59));

      final querySnapshot = await _transactionsCollection
          .where('transactionDate', isGreaterThanOrEqualTo: startOfDay)
          .where('transactionDate', isLessThanOrEqualTo: endOfDay)
          .get();

      final transactions = querySnapshot.docs
          .map((doc) =>
              TransactionModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return Right(transactions);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
