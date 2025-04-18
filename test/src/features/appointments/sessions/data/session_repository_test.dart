import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/session_repository.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';

class MockSessionRepository extends Mock implements SessionRepository {}

void main() {
  group('SessionRepository Tests', () {
    late MockSessionRepository mockSessionRepository;

    setUp(() {
      mockSessionRepository = MockSessionRepository();
    });

    test('should fetch sessions successfully', () async {
      // Arrange
      final sessions = [
        SessionModel(
          id: '1',
          patientId: '123',
          price: 100.0,
          startDateTime: DateTime.now(),
          endDateTime: DateTime.now().add(Duration(hours: 1)),
          sessionType: SessionType.consultation,
        ),
      ];
      when(mockSessionRepository.fetchSessions())
          .thenAnswer((_) async => sessions);

      // Act
      final result = await mockSessionRepository.fetchSessions();

      // Assert
      expect(result, equals(sessions));
      verify(mockSessionRepository.fetchSessions()).called(1);
    });

    test('should add a session successfully', () async {
      // Arrange
      final session = SessionModel(
        id: '1',
        patientId: '123',
        price: 100.0,
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now().add(Duration(hours: 1)),
        sessionType: SessionType.consultation,
      );
      when(mockSessionRepository.addSession(session))
          .thenAnswer((_) async => true);

      // Act
      final result = await mockSessionRepository.addSession(session);

      // Assert
      expect(result, isTrue);
      verify(mockSessionRepository.addSession(session)).called(1);
    });

    test('should delete a session successfully', () async {
      // Arrange
      const sessionId = '1';
      when(mockSessionRepository.deleteSession(sessionId))
          .thenAnswer((_) async => true);

      // Act
      final result = await mockSessionRepository.deleteSession(sessionId);

      // Assert
      expect(result, isTrue);
      verify(mockSessionRepository.deleteSession(sessionId)).called(1);
    });
  });
}
