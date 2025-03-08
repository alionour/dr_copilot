import 'package:dr_copilot/src/features/evaluations/domain/models/evaluation_model.dart';

abstract class EvaluationsRepository {
  Future<void> addEvaluation(EvaluationModel evaluationModel);
  Future<void> updateEvaluation(
       EvaluationModel evaluationModel);
  Future<void> deleteEvaluation(String evaluationId);
  Future<List<EvaluationModel>> getEvaluations();
}
