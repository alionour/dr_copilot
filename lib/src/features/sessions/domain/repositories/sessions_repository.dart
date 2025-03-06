import 'package:cloud_firestore/cloud_firestore.dart';

abstract class SessionsRepository {
  Future<void> addSession(Map<String, dynamic> sessionData);
  Future<void> updateSession(
      String sessionId, Map<String, dynamic> sessionData);
  Future<void> deleteSession(String sessionId);
  Stream<QuerySnapshot> getSessions();
}
