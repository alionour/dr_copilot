import 'package:dr_copilot/src/features/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/evaluations/domain/repositories/evaluations_repository.dart';

class EvaluationsRepositoryImpl implements EvaluationsRepository {
  final EvaluationFirebaseApi _api;

  EvaluationsRepositoryImpl(this._api);

  @override
  Future<void> addEvaluation(EvaluationModel evaluationModel) async {
    await _api.addEvaluation(evaluationModel);
  }

  @override
  Future<void> updateEvaluation(EvaluationModel evaluationModel) async {
    await _api.updateEvaluation(evaluationModel);
  }

  @override
  Future<void> deleteEvaluation(String id) async {
    await _api.deleteEvaluation(id);
  }

  @override
  Future<List<EvaluationModel>> getEvaluations() async {
    return await _api.getEvaluations();
  }
}
