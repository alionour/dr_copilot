import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';

class EvaluationFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<EvaluationModel>> getEvaluations() async {
    try {
      final querySnapshot = await _firestore.collection('evaluations').get();
      return querySnapshot.docs
          .map((doc) => EvaluationModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch evaluations: $e');
    }
  }

  Future<void> addEvaluation(EvaluationModel evaluationModel) async {
    try {
      await _firestore.collection('evaluations').add(evaluationModel.toJson());
    } catch (e) {
      throw Exception('Failed to add evaluation: $e');
    }
  }

  Future<void> updateEvaluation(EvaluationModel evaluationModel) async {
    try {
      await _firestore
          .collection('evaluations')
          .doc(evaluationModel.id)
          .update(evaluationModel.toJson());
    } catch (e) {
      throw Exception('Failed to update evaluation: $e');
    }
  }

  Future<void> deleteEvaluation(String id) async {
    try {
      await _firestore.collection('evaluations').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete evaluation: $e');
    }
  }
}
