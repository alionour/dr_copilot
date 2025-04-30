import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';

// An abstract class that defines the repository for evaluation-related operations.
abstract class AbstractEvaluationsRepository {
  /// Gets a list of evaluations.
  Future<Either<Failure, List<EvaluationModel>>> getEvaluations(
      {String? lastDocumentID, int limit = 20});

  /// Adds a new evaluation.
  Future<Either<Failure, EvaluationModel>> addEvaluation(
      EvaluationModel evaluationModel);

  /// Updates an existing evaluation.
  Future<Either<Failure, EvaluationModel>> updateEvaluation(
      String id, EvaluationModel evaluationModel);

  /// Deletes a evaluation by their ID.
  Future<Either<Failure, void>> deleteEvaluation(String id);

  /// Searches evaluations based on criteria.
  Future<Either<Failure, List<EvaluationModel>>> searchEvaluations(
      {String? name});

  /// Gets evaluations by a specific date.
  Future<Either<Failure, List<EvaluationModel>>> getEvaluationsByDate(
      DateTime date);

  /// Gets the total count of evaluations in Firestore.
  Future<Either<Failure, int>> getEvaluationsCount();

  /// Sums the total price of all evaluations in a specific month for the authenticated user.
  Future<Either<Failure, double>> sumEvaluationCostsForMonth(
      {required int year, required int month});

  /// Sums the total price of all evaluations in a specific year for the authenticated user.
  Future<Either<Failure, double>> sumEvaluationCostsForYear(
      {required int year});

  /// Sums the total price of all evaluations for the authenticated user (all time).
  Future<Either<Failure, double>> sumAllEvaluationCostsForUser();
}
