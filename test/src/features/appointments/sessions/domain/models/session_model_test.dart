import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';

void main() {
  group('SessionModel Tests', () {
    test('should create a valid SessionModel instance', () {
      // Arrange
      final session = SessionModel(
        id: '1',
        patientId: '123',
        userId: '456',
        createdBy: 'admin',
        price: 100.0,
        startDateTime: Timestamp.fromDate(DateTime(2025, 4, 17, 10, 0)),
        endDateTime: Timestamp.fromDate(DateTime(2025, 4, 17, 11, 0)),
        sessionType: SessionType.adultIntensive,
      );

      // Assert
      expect(session.id, '1');
      expect(session.patientId, '123');
      expect(session.price, 100.0);
      expect(session.startDateTime, DateTime(2025, 4, 17, 10, 0));
      expect(session.endDateTime, DateTime(2025, 4, 17, 11, 0));
      expect(session.sessionType, SessionType.adultIntensive);
    });

    test('should copy a SessionModel with updated values', () {
      // Arrange
      final session = SessionModel(
        id: '1',
        patientId: '123',
        price: 100.0,
        startDateTime: DateTime(2025, 4, 17, 10, 0),
        endDateTime: DateTime(2025, 4, 17, 11, 0),
        sessionType: SessionType.consultation,
      );

      // Act
      final updatedSession = session.copyWith(price: 150.0);

      // Assert
      expect(updatedSession.id, '1');
      expect(updatedSession.patientId, '123');
      expect(updatedSession.price, 150.0);
      expect(updatedSession.startDateTime, DateTime(2025, 4, 17, 10, 0));
      expect(updatedSession.endDateTime, DateTime(2025, 4, 17, 11, 0));
      expect(updatedSession.sessionType, SessionType.consultation);
    });
  });
}
