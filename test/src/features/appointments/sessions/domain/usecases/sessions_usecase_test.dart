import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../../../../helpers/test_helpers.dart';

@GenerateMocks([AbstractSessionsRepository])
import 'sessions_usecase_test.mocks.dart';

void main() {
  group('SessionsUseCase Tests', () {
    late SessionsUseCase useCase;
    late MockAbstractSessionsRepository mockRepository;
    late SessionModel testSession;
    late List<SessionModel> testSessions;

    setUp(() {
      mockRepository = MockAbstractSessionsRepository();
      useCase = SessionsUseCase(mockRepository);

      final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 0));
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

      testSessions = [
        testSession,
        SessionModel(
          id: 'session-456',
          patientId: 'patient-456',
          price: 200.0,
          startDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 14, 0)),
          endDateTime: Timestamp.fromDate(DateTime(2024, 1, 15, 15, 0)),
          sessionType: SessionType.adultIntensive,
          ownerId: 'owner-123',
          clinicId: 'clinic-123',
          createdBy: 'user-123',
          patientName: 'Jane Smith',
          createdAt: testTimestamp,
        ),
      ];
    });

    group('getSessions', () {
      test('should return sessions when repository call succeeds', () async {
        // Arrange
        when(mockRepository.getSessions(
          lastDocumentID: anyNamed('lastDocumentID'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Right(testSessions));

        // Act
        final result = await useCase.getSessions(limit: 20);

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessions) {
            expect(sessions.length, equals(2));
            expect(sessions.first.id, equals('session-123'));
            expect(sessions.last.id, equals('session-456'));
          },
        );
        verify(mockRepository.getSessions(
          lastDocumentID: null,
          limit: 20,
        )).called(1);
      });

      test('should pass correct parameters to repository', () async {
        // Arrange
        when(mockRepository.getSessions(
          lastDocumentID: anyNamed('lastDocumentID'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Right(testSessions));

        // Act
        await useCase.getSessions(lastDocumentID: 'last-doc-123', limit: 10);

        // Assert
        verify(mockRepository.getSessions(
          lastDocumentID: 'last-doc-123',
          limit: 10,
        )).called(1);
      });

      test('should return ServerFailure when repository fails', () async {
        // Arrange
        when(mockRepository.getSessions(
          lastDocumentID: anyNamed('lastDocumentID'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => Left(ServerFailure('Network error', 500)));

        // Act
        final result = await useCase.getSessions(limit: 20);

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
    });

    group('addSession', () {
      test('should return created session when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.addSession(any))
            .thenAnswer((_) async => Right(testSession));

        // Act
        final result = await useCase.addSession(testSession);

        // Assert
        expect(result, isA<Right<Failure, SessionModel>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (session) {
            expect(session.id, equals('session-123'));
            expect(session.patientId, equals('patient-123'));
            expect(session.price, equals(150.0));
          },
        );
        verify(mockRepository.addSession(testSession)).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.addSession(any)).thenAnswer(
            (_) async => Left(ServerFailure('Database error', 500)));

        // Act
        final result = await useCase.addSession(testSession);

        // Assert
        expect(result, isA<Left<Failure, SessionModel>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Database error'));
          },
          (session) => fail('Expected failure but got success'),
        );
      });
    });

    group('updateSession', () {
      test('should return updated session when repository call succeeds',
          () async {
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
        final result =
            await useCase.updateSession('session-123', updatedSession);

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
        verify(mockRepository.updateSession('session-123', updatedSession))
            .called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.updateSession(any, any)).thenAnswer(
            (_) async => Left(ServerFailure('Session not found', 404)));

        // Act
        final result = await useCase.updateSession('session-123', testSession);

        // Assert
        expect(result, isA<Left<Failure, SessionModel>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Session not found'));
          },
          (session) => fail('Expected failure but got success'),
        );
      });
    });

    group('deleteSession', () {
      test('should return success when repository call succeeds', () async {
        // Arrange
        when(mockRepository.deleteSession(any))
            .thenAnswer((_) async => const Right(null));

        // Act
        final result = await useCase.deleteSession('session-123');

        // Assert
        expect(result, isA<Right<Failure, void>>());
        verify(mockRepository.deleteSession('session-123')).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.deleteSession(any)).thenAnswer(
            (_) async => Left(ServerFailure('Session not found', 404)));

        // Act
        final result = await useCase.deleteSession('session-123');

        // Assert
        expect(result, isA<Left<Failure, void>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Session not found'));
          },
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('searchSessions', () {
      test('should return filtered sessions when repository call succeeds',
          () async {
        // Arrange
        final filteredSessions = [testSession]; // Only John Doe
        when(mockRepository.searchSessions(name: anyNamed('name')))
            .thenAnswer((_) async => Right(filteredSessions));

        // Act
        final result = await useCase.searchSessions(name: 'John');

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessions) {
            expect(sessions.length, equals(1));
            expect(sessions.first.patientName, contains('John'));
          },
        );
        verify(mockRepository.searchSessions(name: 'John')).called(1);
      });

      test('should return empty list when no matches found', () async {
        // Arrange
        when(mockRepository.searchSessions(name: anyNamed('name')))
            .thenAnswer((_) async => const Right([]));

        // Act
        final result = await useCase.searchSessions(name: 'NonExistent');

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessions) => expect(sessions.isEmpty, isTrue),
        );
      });
    });

    group('getSessionsByDate', () {
      test(
          'should return sessions for specific date when repository call succeeds',
          () async {
        // Arrange
        final targetDate = DateTime(2024, 1, 15);
        when(mockRepository.getSessionsByDate(any))
            .thenAnswer((_) async => Right(testSessions));

        // Act
        final result = await useCase.getSessionsByDate(targetDate);

        // Assert
        expect(result, isA<Right<Failure, List<SessionModel>>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessions) {
            expect(sessions.length, equals(2));
            for (final session in sessions) {
              final sessionDate = session.startDateTime.toDate();
              expect(sessionDate.year, equals(targetDate.year));
              expect(sessionDate.month, equals(targetDate.month));
              expect(sessionDate.day, equals(targetDate.day));
            }
          },
        );
        verify(mockRepository.getSessionsByDate(targetDate)).called(1);
      });
    });

    group('detectSessionType', () {
      test('should return detected session type when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.detectSessionType(any)).thenAnswer(
            (_) async => const Right(SessionType.pediatricIntensive));

        // Act
        final result = await useCase.detectSessionType('patient-123');

        // Assert
        expect(result, isA<Right<Failure, SessionType>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionType) =>
              expect(sessionType, equals(SessionType.pediatricIntensive)),
        );
        verify(mockRepository.detectSessionType('patient-123')).called(1);
      });

      test('should return failure when patient not found', () async {
        // Arrange
        when(mockRepository.detectSessionType(any)).thenAnswer(
            (_) async => Left(ServerFailure('Patient not found', 404)));

        // Act
        final result = await useCase.detectSessionType('invalid-patient');

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
      test('should return total sessions count when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.getSessionsCount())
            .thenAnswer((_) async => const Right(42));

        // Act
        final result = await useCase.getSessionsCount();

        // Assert
        expect(result, isA<Right<Failure, int>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionCount) => expect(sessionCount, equals(42)),
        );
        verify(mockRepository.getSessionsCount()).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.getSessionsCount()).thenAnswer(
            (_) async => Left(ServerFailure('Database error', 500)));

        // Act
        final result = await useCase.getSessionsCount();

        // Assert
        expect(result, isA<Left<Failure, int>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Database error'));
          },
          (sessionCount) => fail('Expected failure but got success'),
        );
      });
    });

    group('getSessionsCountForMonth', () {
      test(
          'should return sessions count for specific month when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.getSessionsCountForMonth(
          year: anyNamed('year'),
          month: anyNamed('month'),
        )).thenAnswer((_) async => const Right(15));

        // Act
        final result =
            await useCase.getSessionsCountForMonth(year: 2024, month: 1);

        // Assert
        expect(result, isA<Right<Failure, int>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionCount) => expect(sessionCount, equals(15)),
        );
        verify(mockRepository.getSessionsCountForMonth(year: 2024, month: 1))
            .called(1);
      });

      test('should return failure when invalid month provided', () async {
        // Arrange
        when(mockRepository.getSessionsCountForMonth(
          year: anyNamed('year'),
          month: anyNamed('month'),
        )).thenAnswer((_) async => Left(ServerFailure('Invalid month', 400)));

        // Act
        final result =
            await useCase.getSessionsCountForMonth(year: 2024, month: 13);

        // Assert
        expect(result, isA<Left<Failure, int>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Invalid month'));
          },
          (sessionCount) => fail('Expected failure but got success'),
        );
      });
    });

    group('getSessionsCountForYear', () {
      test(
          'should return sessions count for specific year when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.getSessionsCountForYear(year: anyNamed('year')))
            .thenAnswer((_) async => const Right(180));

        // Act
        final result = await useCase.getSessionsCountForYear(year: 2024);

        // Assert
        expect(result, isA<Right<Failure, int>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (sessionCount) => expect(sessionCount, equals(180)),
        );
        verify(mockRepository.getSessionsCountForYear(year: 2024)).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.getSessionsCountForYear(year: anyNamed('year')))
            .thenAnswer(
                (_) async => Left(ServerFailure('Database error', 500)));

        // Act
        final result = await useCase.getSessionsCountForYear(year: 2024);

        // Assert
        expect(result, isA<Left<Failure, int>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Database error'));
          },
          (sessionCount) => fail('Expected failure but got success'),
        );
      });
    });

    group('sumSessionCostsForMonth', () {
      test(
          'should return total costs for specific month when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.sumSessionCostsForMonth(
          year: anyNamed('year'),
          month: anyNamed('month'),
        )).thenAnswer((_) async => const Right(2250.0));

        // Act
        final result =
            await useCase.sumSessionCostsForMonth(year: 2024, month: 1);

        // Assert
        expect(result, isA<Right<Failure, double>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (total) => expect(total, equals(2250.0)),
        );
        verify(mockRepository.sumSessionCostsForMonth(year: 2024, month: 1))
            .called(1);
      });

      test('should return zero when no sessions in month', () async {
        // Arrange
        when(mockRepository.sumSessionCostsForMonth(
          year: anyNamed('year'),
          month: anyNamed('month'),
        )).thenAnswer((_) async => const Right(0.0));

        // Act
        final result =
            await useCase.sumSessionCostsForMonth(year: 2024, month: 12);

        // Assert
        expect(result, isA<Right<Failure, double>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (total) => expect(total, equals(0.0)),
        );
      });
    });

    group('sumSessionCostsForYear', () {
      test(
          'should return total costs for specific year when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.sumSessionCostsForYear(year: anyNamed('year')))
            .thenAnswer((_) async => const Right(27000.0));

        // Act
        final result = await useCase.sumSessionCostsForYear(year: 2024);

        // Assert
        expect(result, isA<Right<Failure, double>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (total) => expect(total, equals(27000.0)),
        );
        verify(mockRepository.sumSessionCostsForYear(year: 2024)).called(1);
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.sumSessionCostsForYear(year: anyNamed('year')))
            .thenAnswer(
                (_) async => Left(ServerFailure('Database error', 500)));

        // Act
        final result = await useCase.sumSessionCostsForYear(year: 2024);

        // Assert
        expect(result, isA<Left<Failure, double>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Database error'));
          },
          (total) => fail('Expected failure but got success'),
        );
      });
    });

    group('sumAllSessionCostsForUser', () {
      test(
          'should return total costs for all sessions when repository call succeeds',
          () async {
        // Arrange
        when(mockRepository.sumAllSessionCostsForUser())
            .thenAnswer((_) async => const Right(54000.0));

        // Act
        final result = await useCase.sumAllSessionCostsForUser();

        // Assert
        expect(result, isA<Right<Failure, double>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (total) => expect(total, equals(54000.0)),
        );
        verify(mockRepository.sumAllSessionCostsForUser()).called(1);
      });

      test('should return zero when user has no sessions', () async {
        // Arrange
        when(mockRepository.sumAllSessionCostsForUser())
            .thenAnswer((_) async => const Right(0.0));

        // Act
        final result = await useCase.sumAllSessionCostsForUser();

        // Assert
        expect(result, isA<Right<Failure, double>>());
        result.fold(
          (failure) => fail('Expected success but got failure'),
          (total) => expect(total, equals(0.0)),
        );
      });

      test('should return failure when repository fails', () async {
        // Arrange
        when(mockRepository.sumAllSessionCostsForUser())
            .thenAnswer((_) async => Left(ServerFailure('Access denied', 403)));

        // Act
        final result = await useCase.sumAllSessionCostsForUser();

        // Assert
        expect(result, isA<Left<Failure, double>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, equals('Access denied'));
          },
          (total) => fail('Expected failure but got success'),
        );
      });
    });
  });
}
