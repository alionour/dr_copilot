import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/repositories/abstract_financials_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Handles Firebase operations for financial transactions.
class TransactionsFirebaseApi extends AbstractTransactionsRepository {
  final CollectionReference _transactionsCollection =
      FirebaseFirestore.instance.collection('transactions');

  String? get ownerId => OwnerNotifier().ownerId;

  /// Ensures all queries are scoped to the current user.
  Query _userScopedQuery() =>
      _transactionsCollection.where('ownerId', isEqualTo: ownerId);

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
      Query query = _userScopedQuery()
          .orderBy('transactionDate', descending: true)
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
        // The rest of the logic remains the same
        final docSnapshot = await _transactionsCollection.doc(id).get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data() as Map<String, dynamic>?;
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
            updatedData['updatedAt'] = Timestamp.fromDate(
                DateTime.now().toUtc()); // Add updatedAt field
            await _transactionsCollection.doc(id).update(updatedData);
            _userScopedQuery();
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
        Query queryRef = _userScopedQuery();

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
        Query queryRef = _userScopedQuery()
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
        final snapshot = await _userScopedQuery().get();
        return Right(snapshot.docs.length);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching session count: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Aggregates and returns the total revenue for a given year using Firestore aggregation.
  @override
  Future<Either<Failure, double>> getTotalRevenueForYear(int year) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final start = DateTime(year, 1, 1);
      final end = DateTime(year + 1, 1, 1);
      final query = _userScopedQuery()
          .where('transactionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('transactionDate', isLessThan: Timestamp.fromDate(end))
          .where('direction', isEqualTo: 'in');

      // Attempt Firestore aggregation query on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final aggregate = await query.aggregate(sum('amount')).get();
          final sumValue = aggregate.getSum('amount');
          if (sumValue != null) {
            return Right(sumValue);
          }
        } catch (e) {
          debugPrint('Aggregation query failed: $e');
        }
      }

      // Fallback to manual summation for unsupported platforms
      final snapshot = await query.get();
      double total = snapshot.docs.fold(0.0, (double sum, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = data?['amount'];
        if (amount is num) {
          return sum + amount.toDouble();
        }
        return sum;
      });

      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Aggregates and returns the total expenses for a given year using Firestore aggregation.
  @override
  Future<Either<Failure, double>> getTotalExpensesForYear(int year) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final start = DateTime(year, 1, 1);
      final end = DateTime(year + 1, 1, 1);
      final query = _userScopedQuery()
          .where('transactionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('transactionDate', isLessThan: Timestamp.fromDate(end))
          .where('direction', isEqualTo: 'out');

      // Attempt Firestore aggregation query on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final aggregate = await query.aggregate(sum('amount')).get();
          final sumValue = aggregate.getSum('amount');
          if (sumValue != null) {
            return Right(sumValue);
          }
        } catch (e) {
          debugPrint('Aggregation query failed: $e');
        }
      }

      // Fallback to manual summation for unsupported platforms
      final snapshot = await query.get();
      double total = snapshot.docs.fold(0.0, (acc, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = data?['amount'];
        if (amount is num) {
          return acc + amount.toDouble();
        }
        return acc;
      });

      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Aggregates and returns the total revenue for a given year and month using Firestore aggregation.
  @override
  Future<Either<Failure, double>> getTotalRevenueForMonth(
      int year, int month) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final start = DateTime(year, month, 1);
      final end = (month == 12)
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);
      final query = _userScopedQuery()
          .where('transactionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('transactionDate', isLessThan: Timestamp.fromDate(end))
          .where('direction', isEqualTo: 'in');

      // Attempt Firestore aggregation query on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final aggregate = await query.aggregate(sum('amount')).get();
          final sumValue = aggregate.getSum('amount');
          if (sumValue != null) {
            return Right(sumValue);
          }
        } catch (e) {
          debugPrint('Aggregation query failed: $e');
        }
      }

      // Fallback to manual summation for unsupported platforms
      final snapshot = await query.get();
      double total = snapshot.docs.fold(0.0, (acc, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = data?['amount'];
        if (amount is num) {
          return acc + amount.toDouble();
        }
        return acc;
      });

      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Aggregates and returns the total expenses for a given year and month using Firestore aggregation.
  @override
  Future<Either<Failure, double>> getTotalExpensesForMonth(
      int year, int month) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final start = DateTime(year, month, 1);
      final end = (month == 12)
          ? DateTime(year + 1, 1, 1)
          : DateTime(year, month + 1, 1);
      final query = _userScopedQuery()
          .where('transactionDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('transactionDate', isLessThan: Timestamp.fromDate(end))
          .where('direction', isEqualTo: 'out');

      // Attempt Firestore aggregation query on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final aggregate = await query.aggregate(sum('amount')).get();
          final sumValue = aggregate.getSum('amount');
          if (sumValue != null) {
            return Right(sumValue);
          }
        } catch (e) {
          debugPrint('Aggregation query failed: $e');
        }
      }

      // Fallback to manual summation for unsupported platforms
      final snapshot = await query.get();
      double total = snapshot.docs.fold(0.0, (acc, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = data?['amount'];
        if (amount is num) {
          return acc + amount.toDouble();
        }
        return acc;
      });

      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Aggregates and returns the total for a given direction and optional source, year, and month.
  @override
  Future<Either<Failure, double>> getTotalByDirectionAndSource({
    required TransactionDirection direction,
    TransactionSource? source,
    int? year,
    int? month,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      Query query = _userScopedQuery();

      if (year != null) {
        final start = DateTime(year, month ?? 1, 1);
        final end = (month != null)
            ? ((month == 12)
                ? DateTime(year + 1, 1, 1)
                : DateTime(year, month + 1, 1))
            : DateTime(year + 1, 1, 1);
        query = query
            .where('transactionDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('transactionDate', isLessThan: Timestamp.fromDate(end));
      }

      query = query.where('direction',
          isEqualTo: direction == TransactionDirection.inwards ? 'in' : 'out');

      if (source != null) {
        query = query.where('transactionSource', isEqualTo: source.name);
      }

      // Attempt Firestore aggregation query on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        try {
          final aggregate = await query.aggregate(sum('amount')).get();
          final sumValue = aggregate.getSum('amount');
          if (sumValue != null) {
            return Right(sumValue);
          }
        } catch (e) {
          debugPrint('Aggregation query failed: $e');
        }
      }

      // Fallback to manual summation for unsupported platforms
      final snapshot = await query.get();
      double total = snapshot.docs.fold(0.0, (acc, doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final amount = data?['amount'];
        if (amount is num) {
          return acc + amount.toDouble();
        }
        return acc;
      });

      return Right(total);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Added a method to validate and fetch the linked document based on the transactionSource and referenceId
  @override
  Future<Either<Failure, DocumentSnapshot?>> validateAndFetchReferenceId({
    required String referenceId,
    required TransactionSource transactionSource,
  }) async {
    final collection =
        transactionSource == TransactionSource.invoice ? 'invoices' : 'bills';

    try {
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(referenceId)
          .get();

      if (!doc.exists) {
        return Left(
            ServerFailure('Reference ID not found in $collection', 404));
      }

      return Right(doc);
    } catch (e) {
      return Left(ServerFailure('Error fetching reference ID: $e', 500));
    }
  }

  /// Deletes transactions by their reference ID.
  @override
  Future<Either<Failure, void>> deleteTransactionByReferenceId(
      String referenceId) async {
    try {
      final querySnapshot = await _userScopedQuery()
          .where('referenceId', isEqualTo: referenceId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}

