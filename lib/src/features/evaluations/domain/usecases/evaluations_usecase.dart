import 'package:dr_copilot/src/features/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/evaluations/domain/repositories/evaluations_repository.dart';

class EvaluationsUseCase {
  final EvaluationsRepository _repository;

  EvaluationsUseCase(this._repository);

  Future<List<EvaluationModel>> getEvaluations() async {
    return _repository.getEvaluations();
  }

  Future<void> addEvaluation(EvaluationModel evaluationModel) async {
    await _repository.addEvaluation(evaluationModel);
  }

  Future<void> updateEvaluation(EvaluationModel evaluationModel) async {
    await _repository.updateEvaluation(evaluationModel);
  }

  Future<void> deleteEvaluation(String id) async {
    await _repository.deleteEvaluation(id);
  }
}
