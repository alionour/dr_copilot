import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/repositories/abstract_financials_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Handles Firebase operations for financial transactions.
class TransactionsFirebaseApi extends AbstractTransactionsRepository {
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('transactions');

  /// Checks if the user is authenticated.
  ///
  /// Returns `true` if the user is authenticated, otherwise `false`.
  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  /// Firebase Authentication instance for user authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Adds a new transaction to Firestore.
  @override
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
  @override
  Future<Either<Failure, List<TransactionModel>>> getTransactions({
    String? lastDocumentId,
    int limit = 20,
  }) async {
    try {
      Query query = _transactionsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDocumentSnapshot =
            await _transactionsCollection.doc(lastDocumentId).get();
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
  @override
  Future<Either<Failure, TransactionModel>> updateTransaction(
      String id, TransactionModel transaction) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _transactionsCollection.doc(id).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return Left(ServerFailure('Document data is null', 400));
          }

          final userId = data['userId'] as String?;
          if (userId == null) {
            return Left(ServerFailure('userId field is missing or null', 400));
          }

          if (userId == user.uid) {
            final updatedData = transaction.toJson();
            updatedData.remove('id'); // Exclude the `id` field from the update
            updatedData['updatedAt'] = Timestamp.now(); // Add updatedAt field
            await _transactionsCollection.doc(id).update(updatedData);

            return Right(transaction.copyWith(id: id));
          } else {
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          return Left(ServerFailure('Document does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Deletes a transaction by its ID.
  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _transactionsCollection.doc(id).delete();
      return const Right(null);
    } catch (e) {
      debugPrint(e.toString());
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Searches transactions by description.
  @override
  Future<Either<Failure, List<TransactionModel>>> searchTransactions(
      {String? description}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Query queryRef =
            _transactionsCollection.where('userId', isEqualTo: user.uid);

        if (description != null && description.isNotEmpty) {
          queryRef = queryRef
              .where('description', isGreaterThanOrEqualTo: description)
              .where('description', isLessThanOrEqualTo: '$description\uf8ff');
        }

        debugPrint('Executing query: $queryRef');

        final snapshot = await queryRef.get();

        List<TransactionModel> patients = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          debugPrint('Fetched patient data: $data');
          return TransactionModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();

        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error in searchPatients: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Fetches transactions by a specific date.
  @override
  Future<Either<Failure, List<TransactionModel>>> getTransactionsByDate(
      DateTime date,
      {String? lastDocumentID,
      int limit = 20}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Query queryRef = _transactionsCollection
            .where('userId', isEqualTo: user.uid)
            .where('transactionDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day)))
            .where('transactionDate',
                isLessThan: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day + 1)))
            .limit(limit);

        if (lastDocumentID != null) {
          final lastDocSnapshot =
              await _transactionsCollection.doc(lastDocumentID).get();
          queryRef = queryRef.startAfterDocument(lastDocSnapshot);
        }

        final snapshot = await queryRef.get();

        List<TransactionModel> transactions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return TransactionModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();

        return Right(transactions);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Returns the count of transactions as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getTransactionsCount() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _transactionsCollection
            .where('userId', isEqualTo: user.uid)
            .get();
        return Right(snapshot.docs.length);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching session count: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
