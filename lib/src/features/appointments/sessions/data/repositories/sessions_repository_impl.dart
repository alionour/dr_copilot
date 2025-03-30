import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_api_impl.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/sessions_repository.dart';

class SessionsRepositoryImpl implements SessionsRepository {
  final SessionApiImpl? apiImpl;
  final SessionFirebaseApi? firebaseApi;

  SessionsRepositoryImpl({this.apiImpl, this.firebaseApi});

  @override
  Future<void> addSession(SessionModel session) {
    if (apiImpl != null) {
      return apiImpl!.addSession(session);
    } else if (firebaseApi != null) {
      return firebaseApi!.addSession(session);
    } else {
      throw Exception('No data source provided');
    }
  }

  @override
  Future<void> updateSession( SessionModel sessionModel) {
    if (apiImpl != null) {
      return apiImpl!.updateSession(sessionModel);
    } else if (firebaseApi != null) {
      return firebaseApi!.updateSession(sessionModel);
    } else {
      throw Exception('No data source provided');
    }
  }

  @override
  Future<void> deleteSession(String sessionId) {
    if (apiImpl != null) {
      return apiImpl!.deleteSession(sessionId);
    } else if (firebaseApi != null) {
      return firebaseApi!.deleteSession(sessionId);
    } else {
      throw Exception('No data source provided');
    }
  }

  @override
  Future<List<SessionModel>> getSessions() {
    if (apiImpl != null) {
      return apiImpl!.getSessions();
    } else if (firebaseApi != null) {
      return firebaseApi!.getSessions();
    } else {
      throw Exception('No data source provided');
    }
  }
}
