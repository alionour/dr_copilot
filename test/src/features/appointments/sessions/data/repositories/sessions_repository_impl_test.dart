import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/repositories/sessions_repository_impl.dart';

@GenerateMocks([SessionsFirebaseApi])
void main() {
  group('SessionsRepositoryImpl Tests', () {
    late MockSessionFirebaseApi mockFirebaseApi;
    late SessionsRepositoryImpl repository;

    setUp(() {
      mockFirebaseApi = MockSessionFirebaseApi();
      repository = SessionsRepositoryImpl(firebaseApi: mockFirebaseApi);
    });

    test('should fetch sessions successfully', () async {
      // Arrange
      final sessions = [
        SessionModel(
          id: '1',
          patientId: '123',
          price: 100.0,
          startDateTime: Timestamp.fromDate(DateTime.now()),
          endDateTime:
              Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
          sessionType: SessionType.standard,
          userId: 'user_1',
          createdBy: 'admin',
        ),
      ];
      when(mockFirebaseApi.getSessions(lastDocumentID: null, limit: 20))
          .thenAnswer((_) async => Right(sessions));

      // Act
      final result = await repository.getSessions();

      // Assert
      expect(result, Right(sessions));
      verify(mockFirebaseApi.getSessions(lastDocumentID: null, limit: 20))
          .called(1);
    });

    test('should add a session successfully', () async {
      // Arrange
      final session = SessionModel(
        id: '1',
        patientId: '123',
        price: 100.0,
        startDateTime: Timestamp.fromDate(DateTime.now()),
        endDateTime: Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
        sessionType: SessionType.standard,
        userId: 'user_1',
        createdBy: 'admin',
      );
      when(mockFirebaseApi.addSession(session))
          .thenAnswer((_) async => Right(session));

      // Act
      final result = await repository.addSession(session);

      // Assert
      expect(result, Right(session));
      verify(mockFirebaseApi.addSession(session)).called(1);
    });

    test('should delete a session successfully', () async {
      // Arrange
      const sessionId = '1';
      when(mockFirebaseApi.deleteSession(sessionId))
          .thenAnswer((_) async => const Right(null));

      // Act
      final result = await repository.deleteSession(sessionId);

      // Assert
      expect(result, const Right(null));
      verify(mockFirebaseApi.deleteSession(sessionId)).called(1);
    });
  });
}
