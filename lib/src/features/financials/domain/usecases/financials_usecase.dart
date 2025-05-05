import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';

import '../repositories/abstract_financials_repository.dart';

/// Use case for managing financial transactions.
class FinancialsUseCase {
  final AbstractFinancialsRepository repository;

  /// Constructor for [FinancialsUseCase].
  FinancialsUseCase(this.repository);

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
}
