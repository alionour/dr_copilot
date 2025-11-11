import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/financials/data/remote/abstract_financial_api.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/usecases/transactions_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/bill_model.dart';
import 'package:flutter/material.dart';

import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';

/// Handles Firebase operations for financial transactions.
class FinancialsFirebaseApi extends AbstractFinancialApi {
  // --- Transactions CRUD ---
  final TransactionsUseCase transactionsUseCase;

  /// The owner ID of the user, fetched from Firebase Auth.
  final ownerId = OwnerNotifier().ownerId;

  // Add a transaction
  @override
  Future<Either<Failure, void>> addTransaction(
      {required TransactionModel transaction}) async {
    return await transactionsUseCase.addTransaction(transaction);
  }

  // Update a transaction
  @override
  Future<Either<Failure, TransactionModel>> updateTransaction(
      {required TransactionModel transaction}) async {
    return await transactionsUseCase.updateTransaction(
        transaction.id, transaction);
  }

  // Delete a transaction
  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    return await transactionsUseCase.deleteTransaction(id);
  }

  // Delete a transaction by reference ID
  @override
  Future<Either<Failure, void>> deleteTransactionByReferenceId(
      String referenceId) async {
    return await transactionsUseCase
        .deleteTransactionByReferenceId(referenceId);
  }

  // Fetch all transactions
  @override
  Future<Either<Failure, List<TransactionModel>>> fetchTransactions(
      {String? lastDocumentId, int? limit = 20}) async {
    return await transactionsUseCase.getTransactions(
      lastDocumentId: lastDocumentId,
      limit: limit,
    );
  }

  // --- Invoices CRUD ---
  @override
  Future<Either<Failure, InvoiceModel>> addInvoice(
      {required InvoiceModel invoice}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = invoice.toJson();
        data.remove('id');
        final docRef =
            await FirebaseFirestore.instance.collection('invoices').add(data);
        final newInvoice = invoice.copyWith(
            id: docRef.id, ownerId: ownerId, createdBy: user.uid);
        return Right(newInvoice);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding invoice: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, InvoiceModel>> updateInvoice(
      {required InvoiceModel invoice}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('invoices')
            .doc(invoice.id)
            .update(invoice.toJson());
        return Right(invoice);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating invoice: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceModel>>> fetchInvoices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('invoices')
            .where('ownerId', isEqualTo: ownerId)
            .get();
        final invoices = snapshot.docs.map((doc) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          return InvoiceModel.fromJson({
            ...data,
            'id': doc.id,
            'userId': user.uid,
            'createdAt': (createdAt is Timestamp)
                ? createdAt
                : Timestamp.fromDate(DateTime.now().toUtc()),
          });
        }).toList();
        return Right(invoices);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching invoices: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('invoices')
            .doc(id)
            .delete();
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting invoice: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes an invoice by its reference ID.
  @override
  Future<Either<Failure, InvoiceModel>> deleteInvoiceByReferenceId(
      String referenceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('invoices')
            .where('referenceId', isEqualTo: referenceId)
            .get();
        for (var doc in snapshot.docs) {
          // Get the invoice before deleting
          await doc.reference.delete();
        }

        /// Returns [InvoiceModel]
        return Right(InvoiceModel.fromJson(snapshot.docs.first.data()));
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting invoice by reference ID: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  // --- Bill CRUD ---
  @override
  Future<Either<Failure, BillModel>> addBill({required BillModel bill}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = bill.toJson();
        data.remove('id');
        final docRef =
            await FirebaseFirestore.instance.collection('bills').add(data);
        final newBill = bill.copyWith(id: docRef.id, ownerId: user.uid);
        return Right(newBill);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding bill: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, BillModel>> updateBill(
      {required BillModel bill}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('bills')
            .doc(bill.id)
            .update(bill.toJson());
        return Right(bill);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating bill: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, List<BillModel>>> fetchBills() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('bills')
            .where('ownerId', isEqualTo: ownerId)
            .get();
        final bills = snapshot.docs.map((doc) {
          final data = doc.data();
          final createdAt = data['createdAt'];
          return BillModel.fromJson({
            ...data,
            'id': doc.id,
            'createdAt': (createdAt is Timestamp)
                ? createdAt
                : Timestamp.fromDate(DateTime.now().toUtc()),
          });
        }).toList();
        return Right(bills);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching bills: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBill(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the bill before deleting
        final billDoc =
            await FirebaseFirestore.instance.collection('bills').doc(id).get();
        if (billDoc.exists) {
          final billData = billDoc.data()!;
          final scheduledBillId = billData['scheduledBillId'];
          final dueDate = billData['dueDate'];
          // Only suppress if this is a generated bill (has scheduledBillId)
          if (scheduledBillId != null && dueDate != null) {
            final dueDateStr = (dueDate is Timestamp)
                ? dueDate.toDate().toIso8601String().split('T')[0]
                : dueDate.toString();
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('bill_suppressions')
                .add({
              'scheduledBillId': scheduledBillId,
              'dueDate': dueDateStr,
            });
          }
        }
        await billDoc.reference.delete();
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting bill: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Fetches suppressed due dates for a scheduled bill (returns [Set<String>] of yyyy-MM-dd)
  Future<Set<String>> fetchSuppressedDueDates(String scheduledBillId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('bill_suppressions')
        .where('scheduledBillId', isEqualTo: scheduledBillId)
        .get();
    return snapshot.docs.map((doc) => doc['dueDate'] as String).toSet();
  }

  final SessionsUseCase sessionsUseCase;
  final EvaluationsUseCase evaluationsUseCase;

  FinancialsFirebaseApi({
    required this.sessionsUseCase,
    required this.evaluationsUseCase,
    required this.transactionsUseCase,
  });

  /// Gets the sum of session costs for a given month and year.
  @override
  @Deprecated('Sessions Costs will be calculated from Invoices and Bills')
  Future<Either<Failure, double>> getSessionsSumForMonth(
      {required int year, required int month}) {
    return sessionsUseCase.sumSessionCostsForMonth(year: year, month: month);
  }

  /// Gets the sum of session costs for a given year.
  @override
  @Deprecated('Sessions Costs will be calculated from Invoices and Bills')
  Future<Either<Failure, double>> getSessionsSumForYear({required int year}) {
    return sessionsUseCase.sumSessionCostsForYear(year: year);
  }

  /// Gets the sum of evaluation costs for a given month and year.
  @override
  @Deprecated('Evaluations Costs will be calculated from Invoices and Bills')
  Future<Either<Failure, double>> getEvaluationsSumForMonth(
      {required int year, required int month}) {
    return evaluationsUseCase.sumEvaluationCostsForMonth(
        year: year, month: month);
  }

  /// Gets the sum of evaluation costs for a given year.
  @override
  @Deprecated('Evaluations Costs will be calculated from Invoices and Bills')
  Future<Either<Failure, double>> getEvaluationsSumForYear(
      {required int year}) {
    return evaluationsUseCase.sumEvaluationCostsForYear(year: year);
  }

  /// Gets the count of sessions.
  @override
  Future<Either<Failure, int>> getSessionsCount() {
    return sessionsUseCase.getSessionsCount();
  }

  /// Gets the count of sessions for a specific month and year.
  @override
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) {
    return sessionsUseCase.getSessionsCountForMonth(year: year, month: month);
  }

  /// Gets the count of sessions for a specific year.
  @override
  Future<Either<Failure, int>> getSessionsCountForYear({required int year}) {
    return sessionsUseCase.getSessionsCountForYear(year: year);
  }

  /// Gets the count of evaluations.
  @override
  Future<Either<Failure, int>> getEvaluationsCount() async {
    return await evaluationsUseCase.repository.getEvaluationsCount();
  }

  /// Gets the count of evaluations for a specific month and year.
  @override
  Future<Either<Failure, int>> getEvaluationsCountForMonth(
      {required int year, required int month}) {
    return evaluationsUseCase.getEvaluationsCountForMonth(
        year: year, month: month);
  }

  /// Gets the count of evaluations for a specific year.
  @override
  Future<Either<Failure, int>> getEvaluationsCountForYear({required int year}) {
    return evaluationsUseCase.getEvaluationsCountForYear(year: year);
  }

  /// Adds a new currency profile to the user's currency_profiles subcollection in Firestore.
  /// The document ID will be generated by Firestore and set as the model's id.
  @override
  Future<Either<Failure, CurrencyProfileModel>> addCurrencyProfile({
    required CurrencyProfileModel currencyProfile,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = currencyProfile.toJson();
        data.remove('id'); // Remove id before sending
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('currency_profiles')
            .add(data);
        final newProfile = currencyProfile.copyWith(id: docRef.id);
        return Right(newProfile);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding currency profile: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Fetches all currency profiles for the current user.
  @override
  Future<Either<Failure, List<CurrencyProfileModel>>>
      fetchCurrencyProfiles() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('currency_profiles')
            .get();
        final profiles = snapshot.docs.map((doc) {
          final data = doc.data();
          return CurrencyProfileModel.fromJson({
            ...data,
            'id': doc.id,
          });
        }).toList();
        return Right(profiles);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching currency profiles: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes a currency profile by its document ID for the current user.
  @override
  Future<Either<Failure, void>> deleteCurrencyProfile(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('currency_profiles')
            .doc(id)
            .delete();
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting currency profile: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Updates an existing currency profile for the current user.
  @override
  Future<Either<Failure, CurrencyProfileModel>> updateCurrencyProfile(
      CurrencyProfileModel profile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('currency_profiles')
            .doc(profile.id)
            .update(profile.toJson());
        return Right(profile);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating currency profile: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Adds a new goal for the current user.
  @override
  Future<Either<Failure, GoalModelBase>> addGoal({
    required GoalModelBase goal,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> data;
        GoalModelBase newGoal;
        if (goal is CountGoalModel) {
          data = goal.toJson();
        } else if (goal is AmountGoalModel) {
          data = goal.toJson();
        } else if (goal is CustomGoalModel) {
          data = goal.toJson();
        } else {
          throw Exception('Unknown goal type');
        }
        data.remove('id');
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .add(data);
        if (goal is CountGoalModel) {
          newGoal = goal.copyWith(id: docRef.id);
        } else if (goal is AmountGoalModel) {
          newGoal = goal.copyWith(id: docRef.id);
        } else if (goal is CustomGoalModel) {
          newGoal = goal.copyWith(id: docRef.id);
        } else {
          throw Exception('Unknown goal type');
        }
        return Right(newGoal);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding goal: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Updates an existing goal for the current user.
  @override
  Future<Either<Failure, GoalModelBase>> updateGoal(
      {required GoalModelBase goal}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> data;
        if (goal is CountGoalModel) {
          data = goal.toJson();
        } else if (goal is AmountGoalModel) {
          data = goal.toJson();
        } else if (goal is CustomGoalModel) {
          data = goal.toJson();
        } else {
          throw Exception('Unknown goal type');
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .doc(goal.id)
            .update(data);
        return Right(goal);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating goal: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Fetches all goals for the current user.
  @override
  Future<Either<Failure, List<GoalModelBase>>> fetchGoals() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .get();
        final goals = snapshot.docs.map<GoalModelBase>((doc) {
          final data = doc.data();
          final goalType = goalTypeFromString(data['goalType'] as String);
          final base = {
            ...data,
            'id': doc.id,
          };
          if (goalType.isCountBased) {
            return CountGoalModel.fromJson(base);
          } else if (goalType.isAmountBased) {
            return AmountGoalModel.fromJson(base);
          } else if (goalType.isCustom) {
            return CustomGoalModel.fromJson(base);
          } else {
            // fallback
            return CountGoalModel.fromJson(base);
          }
        }).toList();
        return Right(goals); // No need to cast
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching goals: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes a goal by its document ID for the current user.
  @override
  Future<Either<Failure, void>> deleteGoal(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('goals')
            .doc(id)
            .delete();
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Adds a new scheduled bill for the current user.
  @override
  Future<Either<Failure, ScheduledBillModel>> addScheduledBill(
      {required ScheduledBillModel scheduledBill}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = scheduledBill.toJson();
        data.remove('id');
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_bills')
            .add(data);
        final newBill = scheduledBill.copyWith(id: docRef.id);
        return Right(newBill);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding scheduled bill: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Fetches all scheduled bills for the current user.
  @override
  Future<Either<Failure, List<ScheduledBillModel>>>
      fetchScheduledBills() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_bills')
            .get();
        final bills = snapshot.docs.map((doc) {
          final data = doc.data();
          return ScheduledBillModel.fromJson({
            ...data,
            'id': doc.id,
          });
        }).toList();
        return Right(bills);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching scheduled bills: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Updates an existing scheduled bill for the current user.
  @override
  Future<Either<Failure, ScheduledBillModel>> updateScheduledBill(
      {required ScheduledBillModel scheduledBill}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_bills')
            .doc(scheduledBill.id)
            .update(scheduledBill.toJson());
        return Right(scheduledBill);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating scheduled bill: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes a scheduled bill by its document ID for the current user.
  @override
  Future<Either<Failure, void>> deleteScheduledBill(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('scheduled_bills')
            .doc(id)
            .delete();
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting scheduled bill: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
