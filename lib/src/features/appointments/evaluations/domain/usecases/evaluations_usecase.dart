import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';

class EvaluationsUseCase {
  final AbstractEvaluationsRepository repository;

  EvaluationsUseCase(this.repository);

  /// Gets a list of evaluations.
  Future<Either<Failure, List<EvaluationModel>>> getEvaluations(
      {String? lastDocumentID, int? limit = 20}) async {
    return await repository.getEvaluations(
        lastDocumentID: lastDocumentID, limit: limit ?? 20);
  }

  /// Adds a new evaluation.
  Future<Either<Failure, EvaluationModel>> addEvaluation(
      EvaluationModel evaluationModel) async {
    return await repository.addEvaluation(evaluationModel);
  }

  /// Updates an existing evaluation.
  Future<Either<Failure, EvaluationModel>> updateEvaluation(
      String id, EvaluationModel evaluationModel) async {
    return await repository.updateEvaluation(id, evaluationModel);
  }

  /// Deletes a evaluation by their ID.
  Future<Either<Failure, void>> deleteEvaluation(String id) async {
    return await repository.deleteEvaluation(id);
  }

  /// Searches evaluations based on criteria.
  Future<Either<Failure, List<EvaluationModel>>> searchEvaluations(
      {String? name}) async {
    return await repository.searchEvaluations(name: name);
  }

  /// Gets evaluations by a specific date.
  Future<Either<Failure, List<EvaluationModel>>> getEvaluationsByDate(
      DateTime date) async {
    return await repository.getEvaluationsByDate(date);
  }

  /// Sums the total price of all evaluations in a specific month for the authenticated user.
  Future<Either<Failure, double>> sumEvaluationCostsForMonth(
      {required int year, required int month}) async {
    return await repository.sumEvaluationCostsForMonth(
        year: year, month: month);
  }

  /// Sums the total price of all evaluations in a specific year for the authenticated user.
  Future<Either<Failure, double>> sumEvaluationCostsForYear(
      {required int year}) async {
    return await repository.sumEvaluationCostsForYear(year: year);
  }

  /// Sums the total price of all evaluations for the authenticated user (all time).
  Future<Either<Failure, double>> sumAllEvaluationCostsForUser() async {
    return await repository.sumAllEvaluationCostsForUser();
  }
}
