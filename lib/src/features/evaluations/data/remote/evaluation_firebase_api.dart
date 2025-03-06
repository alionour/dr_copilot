import 'package:cloud_firestore/cloud_firestore.dart';

class EvaluationFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addEvaluation(Map<String, dynamic> evaluationData) async {
    await _firestore.collection('evaluations').add(evaluationData);
  }

  Future<void> updateEvaluation(
      String evaluationId, Map<String, dynamic> evaluationData) async {
    await _firestore
        .collection('evaluations')
        .doc(evaluationId)
        .update(evaluationData);
  }

  Future<void> deleteEvaluation(String evaluationId) async {
    await _firestore.collection('evaluations').doc(evaluationId).delete();
  }

  Stream<QuerySnapshot> getEvaluations() {
    return _firestore.collection('evaluations').snapshots();
  }
}
