import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/evaluations/domain/repositories/evaluations_repository.dart';

class EvaluationsUseCase {
  final EvaluationsRepository _evaluationsRepository;

  EvaluationsUseCase(this._evaluationsRepository);

  Future<void> addEvaluation(Map<String, dynamic> evaluationData) {
    return _evaluationsRepository.addEvaluation(evaluationData);
  }

  Future<void> updateEvaluation(
      String evaluationId, Map<String, dynamic> evaluationData) {
    return _evaluationsRepository.updateEvaluation(
        evaluationId, evaluationData);
  }

  Future<void> deleteEvaluation(String evaluationId) {
    return _evaluationsRepository.deleteEvaluation(evaluationId);
  }

  Stream<QuerySnapshot> getEvaluations() {
    return _evaluationsRepository.getEvaluations();
  }
}
