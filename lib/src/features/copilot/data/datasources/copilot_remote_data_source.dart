import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/copilot/domain/models/copilot_model.dart';

class CopilotRemoteDataSource {
  final FirebaseFirestore _firestore;

  CopilotRemoteDataSource(this._firestore);

  Future<List<CopilotModel>> getCopilots() async {
    final result = await _firestore.collection('copilots').get();
    return result.docs.map((doc) => CopilotModel.fromJson(doc.data())).toList();
  }

  Future<void> addCopilot(CopilotModel copilot) async {
    await _firestore.collection('copilots').add(copilot.toJson());
  }

  Future<void> updateCopilot(CopilotModel copilot) async {
    await _firestore
        .collection('copilots')
        .doc(copilot.id)
        .update(copilot.toJson());
  }

  Future<void> deleteCopilot(String id) async {
    await _firestore.collection('copilots').doc(id).delete();
  }
}
