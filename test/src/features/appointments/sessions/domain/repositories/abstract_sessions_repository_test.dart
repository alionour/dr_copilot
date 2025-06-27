import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../../../helpers/test_helpers.dart';

// Mock implementation of AbstractSessionsRepository for testing
class MockSessionsRepository extends Mock implements AbstractSessionsRepository {}

void main() {
  group('AbstractSessionsRepository Tests', () {
    late MockSessionsRepository mockRepository;
    late SessionModel testSession;
    late Timestamp testTimestamp;

    setUp(() {
      mockRepository = MockSessionsRepository();
      testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 0));
      testSession = SessionModel(
        id: 'session-123',
        patientId: 'patient-123',
        price: 150.0,
        startDateTime: testTimestamp,
        endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 11, 0)),
        sessionType: SessionType.standard,
        ownerId: 'owner-123',
        clinicId: 'clinic-123',
        createdBy: 'user-123',
        patientName: 'John Doe',
        createdAt: testTimestamp,
      );
    });

    group('getSessions', () {
      test('should return list of sessions on success', () async {
        // Arrange
        final sessions = [testSession];
        when(mockRepository.getSessions(lastDocumentID: anyNamed('lastDocumentID'), limit: anyNamed('limit')))
            .thenAnswer((_) async => Right(sessions));

        // Act
        final result = await mockRepository.getSessions(limit: 20);

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionsList) {
            expect(sessionsList.length, equals(1));
            expect(sessionsList.first.id, equals('session-123'));
          },
        );
        verify(mockRepository.getSessions(lastDocumentID: anyNamed('lastDocumentID'), limit: anyNamed('limit'))).called(1);
      });

      test('should return failure when error occurs', () async {
        // Arrange
        when(mockRepository.getSessions(lastDocumentID: anyNamed('lastDocumentID'), limit: anyNamed('limit')))
            .thenAnswer((_) async => Left(ServerFailure('Network error', 500)));

        // Act
        final result = await mockRepository.getSessions(limit: 20);

        // Assert
        expect(result, isA<Left<Failure, List<SessionModel>>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Network error'));
          },
          (sessions) => fail('Expected failure but got success'),
        );
      });

      test('should handle pagination parameters correctly', () async {
        // Arrange
        const lastDocumentID = 'last-doc-123';
        const limit = 10;
        when(mockRepository.getSessions(lastDocumentID: lastDocumentID, limit: limit))
            .thenAnswer((_) async => Right([testSession]));

        // Act
        await mockRepository.getSessions(lastDocumentID: lastDocumentID, limit: limit);

        // Assert
        verify(mockRepository.getSessions(lastDocumentID: lastDocumentID, limit: limit)).called(1);
      });
    });

    group('addSession', () {
      test('should return created session on success', () async {
        // Arrange
        when(mockRepository.addSession(any))
            .thenAnswer((_) async => Right(testSession));

        // Act
        final result = await mockRepository.addSession(testSession);

        // Assert
        expect(result, isA<Right<Failure, SessionModel>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (session) {
            expect(session.id, equals('session-123'));
            expect(session.patientId, equals('patient-123'));
          },
        );
        verify(mockRepository.addSession(testSession)).called(1);
      });

      test('should return failure when creation fails', () async {
        // Arrange
        when(mockRepository.addSession(any))
            .thenAnswer((_) async => Left(ServerFailure('Creation failed', 400)));

        // Act
        final result = await mockRepository.addSession(testSession);

        // Assert
        expect(result, isA<Left<Failure, SessionModel>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Creation failed'));
          },
          (session) => fail('Expected failure but got success'),
        );
      });
    });

    group('updateSession', () {
      test('should return updated session on success', () async {
        // Arrange
        final updatedSession = SessionModel(
          id: testSession.id,
          patientId: testSession.patientId,
          price: 200.0, // Updated price
          startDateTime: testSession.startDateTime,
          endDateTime: testSession.endDateTime,
          sessionType: SessionType.adultIntensive, // Updated type
          ownerId: testSession.ownerId,
          clinicId: testSession.clinicId,
          createdBy: testSession.createdBy,
          patientName: testSession.patientName,
          createdAt: testSession.createdAt,
          updatedBy: 'updater-123',
          updatedAt: Timestamp.now(),
        );

        when(mockRepository.updateSession(any, any))
            .thenAnswer((_) async => Right(updatedSession));

        // Act
        final result = await mockRepository.updateSession('session-123', updatedSession);

        // Assert
        expect(result, isA<Right<Failure, SessionModel>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (session) {
            expect(session.price, equals(200.0));
            expect(session.sessionType, equals(SessionType.adultIntensive));
            expect(session.updatedBy, equals('updater-123'));
          },
        );
        verify(mockRepository.updateSession('session-123', updatedSession)).called(1);
      });

      test('should return failure when update fails', () async {
        // Arrange
        when(mockRepository.updateSession(any, any))
            .thenAnswer((_) async => Left(ServerFailure('Update failed', 404)));

        // Act
        final result = await mockRepository.updateSession('session-123', testSession);

        // Assert
        expect(result, isA<Left<Failure, SessionModel>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Update failed'));
          },
          (session) => fail('Expected failure but got success'),
        );
      });
    });

    group('deleteSession', () {
      test('should return success when deletion succeeds', () async {
        // Arrange
        when(mockRepository.deleteSession(any))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await mockRepository.deleteSession('session-123');

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockRepository.deleteSession('session-123')).called(1);
      });

      test('should return failure when deletion fails', () async {
        // Arrange
        when(mockRepository.deleteSession(any))
            .thenAnswer((_) async => Left(ServerFailure('Deletion failed', 404)));

        // Act
        final result = await mockRepository.deleteSession('session-123');

        // Assert
        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Deletion failed'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('searchSessions', () {
      test('should return filtered sessions on success', () async {
        // Arrange
        final sessions = [testSession];
        when(mockRepository.searchSessions(name: anyNamed('name')))
            .thenAnswer((_) async => Right(sessions));

        // Act
        final result = await mockRepository.searchSessions(name: 'John');

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionsList) {
            expect(sessionsList.length, equals(1));
            expect(sessionsList.first.patientName, contains('John'));
          },
        );
        verify(mockRepository.searchSessions(name: 'John')).called(1);
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        when(mockRepository.searchSessions(name: anyNamed('name')))
            .thenAnswer((_) async => const Right([]));

        // Act
        final result = await mockRepository.searchSessions(name: 'NonExistent');

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionsList) => expect(sessionsList.isEmpty, isTrue),
        );
      });
    });

    group('getSessionsByDate', () {
      test('should return sessions for specific date', () async {
        // Arrange
        final targetDate = DateTime(2024, 1, 15);
        final sessions = [testSession];
        when(mockRepository.getSessionsByDate(any))
            .thenAnswer((_) async => Right(sessions));

        // Act
        final result = await mockRepository.getSessionsByDate(targetDate);

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionsList) {
            expect(sessionsList.length, equals(1));
            final sessionDate = sessionsList.first.startDateTime.toDate();
            expect(sessionDate.year, equals(targetDate.year));
            expect(sessionDate.month, equals(targetDate.month));
            expect(sessionDate.day, equals(targetDate.day));
          },
        );
        verify(mockRepository.getSessionsByDate(targetDate)).called(1);
      });

      test('should return empty list for date with no sessions', () async {
        // Arrange
        final targetDate = DateTime(2024, 12, 25);
        when(mockRepository.getSessionsByDate(any))
            .thenAnswer((_) async => const Right([]));

        // Act
        final result = await mockRepository.getSessionsByDate(targetDate);

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionsList) => expect(sessionsList.isEmpty, isTrue),
        );
      });
    });

    group('detectSessionType', () {
      test('should return detected session type on success', () async {
        // Arrange
        when(mockRepository.detectSessionType(any))
            .thenAnswer((_) async => const Right(SessionType.pediatricIntensive));

        // Act
        final result = await mockRepository.detectSessionType('patient-123');

        // Assert
        expect(result, isA<Right<Failure, SessionType>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionType) => expect(sessionType, equals(SessionType.pediatricIntensive)),
        );
        verify(mockRepository.detectSessionType('patient-123')).called(1);
      });

      test('should return failure when detection fails', () async {
        // Arrange
        when(mockRepository.detectSessionType(any))
            .thenAnswer((_) async => Left(ServerFailure('Patient not found', 404)));

        // Act
        final result = await mockRepository.detectSessionType('invalid-patient');

        // Assert
        expect(result, isA<Left<Failure, SessionType>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Patient not found'));
          },
          (sessionType) => fail('Expected failure but got success'),
        );
      });
    });

    group('getSessionsCount', () {
      test('should return total sessions count', () async {
        // Arrange
        when(mockRepository.getSessionsCount())
            .thenAnswer((_) async => const Right(42));

        // Act
        final result = await mockRepository.getSessionsCount();

        // Assert
        expect(result, isA<Right<Failure, int>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (count) => expect(count, equals(42)),
        );
        verify(mockRepository.getSessionsCount()).called(1);
      });

      test('should return failure when count retrieval fails', () async {
        // Arrange
        when(mockRepository.getSessionsCount())
            .thenAnswer((_) async => Left(ServerFailure('Database error', 500)));

        // Act
        final result = await mockRepository.getSessionsCount();

        // Assert
        expect(result, isA<Left<Failure, int>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Database error'));
          },
          (count) => fail('Expected failure but got success'),
        );
      });
    });

    group('getSessionsCountForMonth', () {
      test('should return sessions count for specific month', () async {
        // Arrange
        when(mockRepository.getSessionsCountForMonth(year: anyNamed('year'), month: anyNamed('month')))
            .thenAnswer((_) async => const Right(15));

        // Act
        final result = await mockRepository.getSessionsCountForMonth(year: 2024, month: 1);

        // Assert
        expect(result, isA<Right<Failure, int>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (count) => expect(count, equals(15)),
        );
        verify(mockRepository.getSessionsCountForMonth(year: 2024, month: 1)).called(1);
      });

      test('should validate month and year parameters', () async {
        // Arrange
        when(mockRepository.getSessionsCountForMonth(year: anyNamed('year'), month: anyNamed('month')))
            .thenAnswer((_) async => Left(ValidationFailure('Invalid month')));

        // Act
        final result = await mockRepository.getSessionsCountForMonth(year: 2024, month: 13); // Invalid month

        // Assert
        expect(result, isA<Left<Failure, int>>());
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, equals('Invalid month'));
          },
          (count) => fail('Expected failure but got success'),
        );
      });
    });
  });
}
