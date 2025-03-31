import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';

class SessionFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SessionFirebaseApi();

  Future<void> addSession(SessionModel session) async {
    await _firestore.collection('sessions').add(session.toJson());
  }

  Future<void> updateSession(SessionModel session) async {
    await _firestore
        .collection('sessions')
        .doc(session.id)
        .update(session.toJson());
  }

  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).delete();
  }

  Future<List<SessionModel>> getSessions() async {
    final snapshot = await _firestore.collection('sessions').get();
    return snapshot.docs
        .map((doc) => SessionModel.fromJson(doc.data()))
        .toList();
  }
}
