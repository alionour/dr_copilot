import 'package:dr_copilot/src/features/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/sessions/domain/repositories/sessions_repository.dart';

class SessionsUseCase {
  final SessionsRepository _sessionsRepository;

  SessionsUseCase(this._sessionsRepository);

  Future<void> addSession(SessionModel session) {
    return _sessionsRepository.addSession(session);
  }

  Future<void> updateSession(SessionModel sessionModel) {
    return _sessionsRepository.updateSession(sessionModel);
  }

  Future<void> deleteSession(String sessionId) {
    return _sessionsRepository.deleteSession(sessionId);
  }

  Future<List<SessionModel>> getSessions() {
    return _sessionsRepository.getSessions();
  }
}
