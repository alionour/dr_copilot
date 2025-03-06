import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/sessions/domain/repositories/sessions_repository.dart';

class SessionsRepositoryImpl implements SessionsRepository {
  final SessionFirebaseApi _sessionFirebaseApi;

  SessionsRepositoryImpl(this._sessionFirebaseApi);

  @override
  Future<void> addSession(Map<String, dynamic> sessionData) {
    return _sessionFirebaseApi.addSession(sessionData);
  }

  @override
  Future<void> updateSession(
      String sessionId, Map<String, dynamic> sessionData) {
    return _sessionFirebaseApi.updateSession(sessionId, sessionData);
  }

  @override
  Future<void> deleteSession(String sessionId) {
    return _sessionFirebaseApi.deleteSession(sessionId);
  }

  @override
  Stream<QuerySnapshot> getSessions() {
    return _sessionFirebaseApi.getSessions();
  }
}
