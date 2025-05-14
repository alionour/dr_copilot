import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/data/remote/financials_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';
import 'package:dr_copilot/src/features/financials/domain/repositories/abstract_financials_repository.dart';
import 'package:dr_copilot/src/features/financials/domain/models/bill_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';

import 'package:firebase_auth/firebase_auth.dart';

class FinancialsRepositoryImpl extends AbstractFinancialsRepository {
  /// Returns the current authenticated user's UID, or null if not signed in.
  @override
  String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  @override
  Future<Set<String>> fetchSuppressedDueDates(String scheduledBillId) {
    return firebaseApi.fetchSuppressedDueDates(scheduledBillId);
  }

  // --- Bill CRUD ---
  @override
  Future<Either<Failure, BillModel>> addBill({required BillModel bill}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      bill = bill.copyWith(
        userId: userId,
        createdBy: userId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.addBill(bill: bill);
  }

  @override
  Future<Either<Failure, BillModel>> updateBill({required BillModel bill}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      bill = bill.copyWith(
        updatedBy: userId,
        updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    // Ensure the userId is set before updating
    return firebaseApi.updateBill(bill: bill);
  }

  @override
  Future<Either<Failure, List<BillModel>>> fetchBills() {
    return firebaseApi.fetchBills();
  }

  //TODO do not delete doc Mark as deleted flag
  @override
  Future<Either<Failure, void>> deleteBill(String id) {
    return firebaseApi.deleteBill(id);
  }

  final FinancialsFirebaseApi firebaseApi;

  FinancialsRepositoryImpl(this.firebaseApi);

  /// Retrieves the total number of sessions for a specified year.
  ///
  /// Returns an [Either] containing a [Failure] if an error occurs,
  /// or an [int] representing the count of sessions for the given [year].
  ///
  /// [year]: The year for which to count the sessions.
  @override
  Future<Either<Failure, int>> getSessionsCountForYear({required int year}) {
    return firebaseApi.getSessionsCountForYear(year: year);
  }

  /// Retrieves the total number of sessions for a specific month.
  ///
  /// Returns an [Either] containing a [Failure] if an error occurs,
  /// or an [int] representing the count of sessions for the month.
  @override
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) {
    return firebaseApi.getSessionsCountForMonth(year: year, month: month);
  }

  /// Retrieves the count of evaluations for a specified year.
  ///
  /// Returns a [Future] that completes with an [Either] containing a [Failure]
  /// if an error occurs, or an [int] representing the number of evaluations
  /// for the given [year].
  ///
  /// [year]: The year for which to count evaluations.
  @override
  Future<Either<Failure, int>> getEvaluationsCountForYear({required int year}) {
    return firebaseApi.getEvaluationsCountForYear(year: year);
  }

  /// Retrieves the count of evaluations for the specified month.
  ///
  /// Returns a [Future] that completes with either a [Failure] or the count of evaluations as an [int].
  @override
  Future<Either<Failure, int>> getEvaluationsCountForMonth(
      {required int year, required int month}) {
    return firebaseApi.getEvaluationsCountForMonth(year: year, month: month);
  }

  /// Fetches all currency profiles for the current user.
  @override
  Future<Either<Failure, List<CurrencyProfileModel>>> fetchCurrencyProfiles() {
    return firebaseApi.fetchCurrencyProfiles();
  }

  /// Adds a new currency profile for the current user.
  @override
  Future<Either<Failure, CurrencyProfileModel>> addCurrencyProfile({
    required CurrencyProfileModel currencyProfile,
  }) {
    final userId = getCurrentUserId();
    if (userId != null) {
      currencyProfile = currencyProfile.copyWith(
        createdBy: userId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.addCurrencyProfile(currencyProfile: currencyProfile);
  }

  /// Deletes a currency profile by its document ID for the current user.
  @override
  Future<Either<Failure, void>> deleteCurrencyProfile(String id) {
    return firebaseApi.deleteCurrencyProfile(id);
  }

  /// Updates an existing currency profile for the current user.
  @override
  Future<Either<Failure, CurrencyProfileModel>> updateCurrencyProfile(
      CurrencyProfileModel profile) {
    final userId = getCurrentUserId();
    if (userId != null) {
      profile = profile.copyWith(
        updatedBy: userId,
        updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.updateCurrencyProfile(profile);
  }

  /// Gets the sum of session costs for a given month and year.
  @override
  Future<Either<Failure, double>> getSessionsSumForMonth(
      {required int year, required int month}) {
    return firebaseApi.getSessionsSumForMonth(year: year, month: month);
  }

  /// Gets the sum of session costs for a given year.
  @override
  Future<Either<Failure, double>> getSessionsSumForYear({required int year}) {
    return firebaseApi.getSessionsSumForYear(year: year);
  }

  /// Gets the sum of evaluation costs for a given month and year.
  @override
  Future<Either<Failure, double>> getEvaluationsSumForMonth(
      {required int year, required int month}) {
    return firebaseApi.getEvaluationsSumForMonth(year: year, month: month);
  }

  /// Gets the sum of evaluation costs for a given year.
  @override
  Future<Either<Failure, double>> getEvaluationsSumForYear(
      {required int year}) {
    return firebaseApi.getEvaluationsSumForYear(year: year);
  }

  /// Gets the count of sessions.
  @override
  Future<Either<Failure, int>> getSessionsCount() {
    return firebaseApi.getSessionsCount();
  }

  /// Gets the count of evaluations.
  @override
  Future<Either<Failure, int>> getEvaluationsCount() {
    return firebaseApi.getEvaluationsCount();
  }

  // --- Goal CRUD ---
  @override
  Future<Either<Failure, GoalModelBase>> addGoal(
      {required GoalModelBase goal}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      if (goal is CountGoalModel) {
        goal = (goal).copyWith(
          createdBy: userId,
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
        );
      } else if (goal is AmountGoalModel) {
        goal = (goal).copyWith(
          createdBy: userId,
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
        );
      } else if (goal is CustomGoalModel) {
        goal = (goal).copyWith(
          createdBy: userId,
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
        );
      }
      // else: leave as is for other GoalModelBase types
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.addGoal(goal: goal);
  }

  @override
  Future<Either<Failure, GoalModelBase>> updateGoal(
      {required GoalModelBase goal}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      if (goal is CountGoalModel) {
        goal = (goal).copyWith(
          updatedBy: userId,
          updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
        );
      } else if (goal is AmountGoalModel) {
        goal = (goal).copyWith(
          updatedBy: userId,
          updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
        );
      } else if (goal is CustomGoalModel) {
        goal = (goal).copyWith(
          updatedBy: userId,
          updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
        );
      }
      // else: leave as is for other GoalModelBase types
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.updateGoal(goal: goal);
  }

  @override
  Future<Either<Failure, List<GoalModelBase>>> fetchGoals() {
    return firebaseApi.fetchGoals();
  }

  @override
  Future<Either<Failure, void>> deleteGoal(String id) {
    return firebaseApi.deleteGoal(id);
  }

  // --- Scheduled Bill CRUD ---
  @override
  Future<Either<Failure, ScheduledBillModel>> addScheduledBill(
      {required ScheduledBillModel scheduledBill}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      scheduledBill = scheduledBill.copyWith(
        createdBy: userId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.addScheduledBill(scheduledBill: scheduledBill);
  }

  @override
  Future<Either<Failure, ScheduledBillModel>> updateScheduledBill(
      {required ScheduledBillModel scheduledBill}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      scheduledBill = scheduledBill.copyWith(
        updatedBy: userId,
        updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.updateScheduledBill(scheduledBill: scheduledBill);
  }

  @override
  Future<Either<Failure, List<ScheduledBillModel>>> fetchScheduledBills() {
    return firebaseApi.fetchScheduledBills();
  }

  @override
  Future<Either<Failure, void>> deleteScheduledBill(String id) {
    return firebaseApi.deleteScheduledBill(id);
  }

  // --- Invoice CRUD ---

  @override
  Future<Either<Failure, InvoiceModel>> addInvoice(
      {required InvoiceModel invoice}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      invoice = invoice.copyWith(
        userId: userId,
        createdBy: userId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.addInvoice(invoice: invoice);
  }

  @override
  Future<Either<Failure, InvoiceModel>> updateInvoice(
      {required InvoiceModel invoice}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      invoice = invoice.copyWith(
        updatedBy: userId,
        updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.updateInvoice(invoice: invoice);
  }

  @override
  Future<Either<Failure, List<InvoiceModel>>> fetchInvoices() {
    return firebaseApi.fetchInvoices();
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(String id) {
    return firebaseApi.deleteInvoice(id);
  }

  /// Deletes an invoice by its reference ID.
  @override
  Future<Either<Failure, InvoiceModel>> deleteInvoiceByReferenceId(String referenceId) {
    return firebaseApi.deleteInvoiceByReferenceId(referenceId);
  }

  @override
  Future<Either<Failure, void>> addTransaction(
      {required TransactionModel transaction}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      transaction = transaction.copyWith(
        userId: userId,
        createdBy: userId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.addTransaction(transaction: transaction);
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) {
    return firebaseApi.deleteTransaction(id);
  }

  /// Deletes a transaction by its reference ID.
  @override
  Future<Either<Failure, void>> deleteTransactionByReferenceId(String referenceId) {
    return firebaseApi.deleteTransactionByReferenceId(referenceId);
  }

  @override
  Future<Either<Failure, List<TransactionModel>>> fetchTransactions() {
    return firebaseApi.fetchTransactions();
  }

  @override
  Future<Either<Failure, TransactionModel>> updateTransaction(
      {required TransactionModel transaction}) {
    final userId = getCurrentUserId();
    if (userId != null) {
      transaction = transaction.copyWith(
        updatedBy: userId,
        updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );
    } else {
      return Future.value(Left(ServerFailure('User not authenticated', 401)));
    }
    return firebaseApi.updateTransaction(transaction: transaction);
  }
}
