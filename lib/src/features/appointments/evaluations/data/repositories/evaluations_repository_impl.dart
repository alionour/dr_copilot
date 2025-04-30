import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';

class EvaluationsRepositoryImpl extends AbstractEvaluationsRepository {
  final EvaluationsFirebaseApi firebaseApi;

  EvaluationsRepositoryImpl(this.firebaseApi);

  /// Gets a list of evaluations.
  @override
  Future<Either<Failure, List<EvaluationModel>>> getEvaluations(
      {String? lastDocumentID, int limit = 20}) {
    return firebaseApi.getEvaluations(
        lastDocumentID: lastDocumentID, limit: limit);
  }

  /// Adds a new evaluation.
  @override
  Future<Either<Failure, EvaluationModel>> addEvaluation(
      EvaluationModel evaluationModel) {
    return firebaseApi.addEvaluation(evaluationModel);
  }

  /// Updates an existing evaluation.
  @override
  Future<Either<Failure, EvaluationModel>> updateEvaluation(
      String id, EvaluationModel evaluationModel) {
    return firebaseApi.updateEvaluation(id, evaluationModel);
  }

  /// Deletes a evaluation by their ID.
  @override
  Future<Either<Failure, void>> deleteEvaluation(String id) {
    return firebaseApi.deleteEvaluation(id);
  }

  /// Searches evaluations based on criteria.
  @override
  Future<Either<Failure, List<EvaluationModel>>> searchEvaluations(
      {String? name}) {
    return firebaseApi.searchEvaluations(name: name);
  }

  /// Gets evaluations by a specific date.
  @override
  Future<Either<Failure, List<EvaluationModel>>> getEvaluationsByDate(
      DateTime date) {
    return firebaseApi.getEvaluationsByDate(date);
  }

  /// Gets the total count of evaluations in Firestore.
  @override
  Future<Either<Failure, int>> getEvaluationsCount() {
    return firebaseApi.getEvaluationsCount();
  }

  /// Sums the total price of all evaluations in a specific month for the authenticated user.
  @override
  Future<Either<Failure, double>> sumEvaluationCostsForMonth(
      {required int year, required int month}) {
    return firebaseApi.sumEvaluationCostsForMonth(year: year, month: month);
  }

  /// Sums the total price of all evaluations in a specific year for the authenticated user.
  @override
  Future<Either<Failure, double>> sumEvaluationCostsForYear(
      {required int year}) {
    return firebaseApi.sumEvaluationCostsForYear(year: year);
  }

  /// Sums the total price of all evaluations for the authenticated user (all time).
  @override
  Future<Either<Failure, double>> sumAllEvaluationCostsForUser() {
    return firebaseApi.sumAllEvaluationCostsForUser();
  }
}
