import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/correction_model.dart';

class CorrectionService {
  final FirebaseFirestore _firestore;

  CorrectionService(this._firestore);

  Future<void> saveCorrection(CorrectionModel correction) async {
    await _firestore.collection('corrections').doc(correction.id).set({
      'originalCommand': {
        'intent': correction.originalCommand.intent,
        'entities': correction.originalCommand.entities,
      },
      'correctedCommand': {
        'intent': correction.correctedCommand.intent,
        'entities': correction.correctedCommand.entities,
      },
      'createdAt': correction.createdAt,
    });
  }
}
