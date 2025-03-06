import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/sessions/domain/repositories/sessions_repository.dart';

class SessionsUseCase {
  final SessionsRepository _sessionsRepository;

  SessionsUseCase(this._sessionsRepository);

  Future<void> addSession(Map<String, dynamic> sessionData) {
    return _sessionsRepository.addSession(sessionData);
  }

  Future<void> updateSession(
      String sessionId, Map<String, dynamic> sessionData) {
    return _sessionsRepository.updateSession(sessionId, sessionData);
  }

  Future<void> deleteSession(String sessionId) {
    return _sessionsRepository.deleteSession(sessionId);
  }

  Stream<QuerySnapshot> getSessions() {
    return _sessionsRepository.getSessions();
  }
}
