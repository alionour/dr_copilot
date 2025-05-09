import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import '../repositories/abstract_financials_repository.dart';
import '../models/bill_model.dart';

/// Use case for managing financial transactions.
class FinancialsUseCase {
  /// Fetches suppressed due dates (yyyy-MM-dd) for a scheduled bill.
  Future<Set<String>> fetchSuppressedDueDates(String scheduledBillId) {
    return repository.fetchSuppressedDueDates(scheduledBillId);
  }

  // --- Bill CRUD ---
  Future<Either<Failure, BillModel>> addBill({required BillModel bill}) {
    return repository.addBill(bill: bill);
  }

  Future<Either<Failure, BillModel>> updateBill({required BillModel bill}) {
    return repository.updateBill(bill: bill);
  }

  Future<Either<Failure, List<BillModel>>> fetchBills() {
    return repository.fetchBills();
  }

  Future<Either<Failure, void>> deleteBill(String id) {
    return repository.deleteBill(id);
  }

  final AbstractFinancialsRepository repository;

  /// Constructor for [FinancialsUseCase].
  FinancialsUseCase(this.repository,);

  Future<Either<Failure, int>> getSessionsCountForYear({required int year}) {
    return repository.getSessionsCountForYear(year: year);
  }

  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) {
    return repository.getSessionsCountForMonth(year: year, month: month);
  }

  Future<Either<Failure, int>> getEvaluationsCountForYear({required int year}) {
    return repository.getEvaluationsCountForYear(year: year);
  }

  Future<Either<Failure, int>> getEvaluationsCountForMonth(
      {required int year, required int month}) {
    return repository.getEvaluationsCountForMonth(year: year, month: month);
  }

  Future<Either<Failure, List<CurrencyProfileModel>>> fetchCurrencyProfiles() {
    return repository.fetchCurrencyProfiles();
  }

  Future<Either<Failure, CurrencyProfileModel>> addCurrencyProfile({
    required CurrencyProfileModel currencyProfile,
  }) {
    return repository.addCurrencyProfile(currencyProfile: currencyProfile);
  }

  Future<Either<Failure, void>> deleteCurrencyProfile(String id) {
    return repository.deleteCurrencyProfile(id);
  }

  Future<Either<Failure, CurrencyProfileModel>> updateCurrencyProfile(
      CurrencyProfileModel profile) {
    return repository.updateCurrencyProfile(profile);
  }

  Future<Either<Failure, double>> getSessionsSumForMonth(
      {required int year, required int month}) {
    return repository.getSessionsSumForMonth(year: year, month: month);
  }

  Future<Either<Failure, double>> getSessionsSumForYear({required int year}) {
    return repository.getSessionsSumForYear(year: year);
  }

  Future<Either<Failure, double>> getEvaluationsSumForMonth(
      {required int year, required int month}) {
    return repository.getEvaluationsSumForMonth(year: year, month: month);
  }

  Future<Either<Failure, double>> getEvaluationsSumForYear(
      {required int year}) {
    return repository.getEvaluationsSumForYear(year: year);
  }

  Future<Either<Failure, int>> getSessionsCount() {
    return repository.getSessionsCount();
  }

  Future<Either<Failure, int>> getEvaluationsCount() {
    return repository.getEvaluationsCount();
  }

  // --- Goal CRUD ---
  Future<Either<Failure, GoalModelBase>> addGoal(
      {required GoalModelBase goal}) {
    return repository.addGoal(goal: goal);
  }

  Future<Either<Failure, GoalModelBase>> updateGoal(
      {required GoalModelBase goal}) {
    return repository.updateGoal(goal: goal);
  }

  Future<Either<Failure, List<GoalModelBase>>> fetchGoals() {
    return repository.fetchGoals();
  }

  Future<Either<Failure, void>> deleteGoal(String id) {
    return repository.deleteGoal(id);
  }

  // --- Scheduled Bill CRUD ---
  Future<Either<Failure, ScheduledBillModel>> addScheduledBill(
      {required ScheduledBillModel scheduledBill}) {
    return repository.addScheduledBill(scheduledBill: scheduledBill);
  }

  Future<Either<Failure, ScheduledBillModel>> updateScheduledBill(
      {required ScheduledBillModel scheduledBill}) {
    return repository.updateScheduledBill(scheduledBill: scheduledBill);
  }

  Future<Either<Failure, List<ScheduledBillModel>>> fetchScheduledBills() {
    return repository.fetchScheduledBills();
  }

  Future<Either<Failure, void>> deleteScheduledBill(String id) {
    return repository.deleteScheduledBill(id);
  }

  // --- Invoice CRUD ---
  Future<Either<Failure, InvoiceModel>> addInvoice(
      {required InvoiceModel invoice}) {
    return repository.addInvoice(invoice: invoice);
  }

  Future<Either<Failure, InvoiceModel>> updateInvoice(
      {required InvoiceModel invoice}) {
    return repository.updateInvoice(invoice: invoice);
  }

  Future<Either<Failure, List<InvoiceModel>>> fetchInvoices() {
    return repository.fetchInvoices();
  }

  Future<Either<Failure, void>> deleteInvoice(String id) {
    return repository.deleteInvoice(id);
  }

  // --- Transactions CRUD ---
  Future<Either<Failure, void>> addTransaction(
      {required TransactionModel transaction}) {
    return repository.addTransaction(transaction: transaction);
  }

  Future<Either<Failure, TransactionModel>> updateTransaction(
      {required TransactionModel transaction}) {
    return repository.updateTransaction(transaction: transaction);
  }

  Future<Either<Failure, List<TransactionModel>>> fetchTransactions() {
    return repository.fetchTransactions();
  }

  Future<Either<Failure, void>> deleteTransaction(String id) {
    return repository.deleteTransaction(id);
  }
}
