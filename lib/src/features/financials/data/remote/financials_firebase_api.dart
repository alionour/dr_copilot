import 'package:dr_copilot/src/features/financials/data/remote/abstract_financial_api.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';

/// Handles Firebase operations for financial transactions.
class FinancialsFirebaseApi extends AbstractFinancialApi {
  final SessionsUseCase sessionsUseCase;
  final EvaluationsUseCase evaluationsUseCase;

  FinancialsFirebaseApi({
    required this.sessionsUseCase,
    required this.evaluationsUseCase,
  });

  @override
  Future<TransactionModel> addFinancial(TransactionModel financial) {
    // TODO: implement addFinancial
    throw UnimplementedError();
  }

  @override
  Future<void> deleteFinancial(String financialId) {
    // TODO: implement deleteFinancial
    throw UnimplementedError();
  }

  /// Gets all transactions (financial records).
  @override
  Future<List<TransactionModel>> fetchFinancials() {
    // TODO: implement fetchFinancials
    throw UnimplementedError();
  }

  @override
  Future<TransactionModel> updateFinancial(TransactionModel financial) {
    // TODO: implement updateFinancial
    throw UnimplementedError();
  }

  /// Gets the sum of session costs for a given month and year.
  Future<Either<Failure, double>> getSessionsSumForMonth(
      {required int year, required int month}) {
    return sessionsUseCase.sumSessionCostsForMonth(year: year, month: month);
  }

  /// Gets the sum of session costs for a given year.
  Future<Either<Failure, double>> getSessionsSumForYear({required int year}) {
    return sessionsUseCase.sumSessionCostsForYear(year: year);
  }

  /// Gets the sum of evaluation costs for a given month and year.
  Future<Either<Failure, double>> getEvaluationsSumForMonth(
      {required int year, required int month}) {
    return evaluationsUseCase.sumEvaluationCostsForMonth(
        year: year, month: month);
  }

  /// Gets the sum of evaluation costs for a given year.
  Future<Either<Failure, double>> getEvaluationsSumForYear(
      {required int year}) {
    return evaluationsUseCase.sumEvaluationCostsForYear(year: year);
  }

  /// Gets the count of sessions.
  Future<Either<Failure, int>> getSessionsCount() {
    return sessionsUseCase.getSessionsCount();
  }

  /// Gets the count of sessions for a specific month and year.
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) {
    return sessionsUseCase.getSessionsCountForMonth(year: year, month: month);
  }

  /// Gets the count of sessions for a specific year.
  Future<Either<Failure, int>> getSessionsCountForYear({required int year}) {
    return sessionsUseCase.getSessionsCountForYear(year: year);
  }

  /// Gets the count of evaluations.
  Future<Either<Failure, int>> getEvaluationsCount() async {
    return await evaluationsUseCase.repository.getEvaluationsCount();
  }

  /// Gets the count of evaluations for a specific month and year.
  Future<Either<Failure, int>> getEvaluationsCountForMonth(
      {required int year, required int month}) {
    return evaluationsUseCase.getEvaluationsCountForMonth(
        year: year, month: month);
  }

  /// Gets the count of evaluations for a specific year.
  Future<Either<Failure, int>> getEvaluationsCountForYear({required int year}) {
    return evaluationsUseCase.getEvaluationsCountForYear(year: year);
  }
}
