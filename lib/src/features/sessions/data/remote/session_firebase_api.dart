import 'package:cloud_firestore/cloud_firestore.dart';

class SessionFirebaseApi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addSession(Map<String, dynamic> sessionData) async {
    await _firestore.collection('sessions').add(sessionData);
  }

  Future<void> updateSession(
      String sessionId, Map<String, dynamic> sessionData) async {
    await _firestore.collection('sessions').doc(sessionId).update(sessionData);
  }

  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection('sessions').doc(sessionId).delete();
  }

  Stream<QuerySnapshot> getSessions() {
    return _firestore.collection('sessions').snapshots();
  }
}
