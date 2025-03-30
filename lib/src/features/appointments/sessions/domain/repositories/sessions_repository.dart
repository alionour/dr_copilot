import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';

abstract class SessionsRepository {
  Future<void> addSession(SessionModel sessionModel);
  Future<void> updateSession(SessionModel sessionModel);
  Future<void> deleteSession(String sessionId);
  Future<List<SessionModel>> getSessions();
}
