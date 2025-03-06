import 'package:cloud_firestore/cloud_firestore.dart';

abstract class EvaluationsRepository {
  Future<void> addEvaluation(Map<String, dynamic> evaluationData);
  Future<void> updateEvaluation(
      String evaluationId, Map<String, dynamic> evaluationData);
  Future<void> deleteEvaluation(String evaluationId);
  Stream<QuerySnapshot> getEvaluations();
}
