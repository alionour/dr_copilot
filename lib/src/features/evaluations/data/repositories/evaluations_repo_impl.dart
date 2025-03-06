import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/evaluations/domain/repositories/evaluations_repository.dart';

class EvaluationsRepositoryImpl implements EvaluationsRepository {
  final EvaluationFirebaseApi _evaluationFirebaseApi;

  EvaluationsRepositoryImpl(this._evaluationFirebaseApi);

  @override
  Future<void> addEvaluation(Map<String, dynamic> evaluationData) {
    return _evaluationFirebaseApi.addEvaluation(evaluationData);
  }

  @override
  Future<void> updateEvaluation(
      String evaluationId, Map<String, dynamic> evaluationData) {
    return _evaluationFirebaseApi.updateEvaluation(
        evaluationId, evaluationData);
  }

  @override
  Future<void> deleteEvaluation(String evaluationId) {
    return _evaluationFirebaseApi.deleteEvaluation(evaluationId);
  }

  @override
  Stream<QuerySnapshot> getEvaluations() {
    return _evaluationFirebaseApi.getEvaluations();
  }
}
