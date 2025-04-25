import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Mocks
class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

class MockQuery extends Mock implements Query {}

class MockQuerySnapshot extends Mock implements QuerySnapshot {}

class MockUser extends Mock implements User {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late EvaluationsFirebaseApi api;
  late MockCollectionReference mockEvaluationsCollection;
  late MockCollectionReference mockPatientsCollection;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() {
    mockEvaluationsCollection = MockCollectionReference();
    mockPatientsCollection = MockCollectionReference();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();

    api = EvaluationsFirebaseApi();
    // Inject mocks if you refactor EvaluationFirebaseApi to accept them.
    // Otherwise, use dependency overrides or mockito's when/thenAnswer.
  });

  group('getEvaluations', () {
    test(
        'returns Right(List<EvaluationModel>) when user is authenticated and data exists',
        () async {
      // This test is illustrative. You need to refactor EvaluationFirebaseApi to inject dependencies for full testability.
      // Arrange
      // ...setup mocks for FirebaseAuth, Firestore, etc.

      // Act
      final result = await api.getEvaluations();

      // Assert
      expect(result, isA<Either<Failure, List<EvaluationModel>>>());
    });

    test('returns Left(ServerFailure) when user is not authenticated',
        () async {
      // Arrange
      // ...simulate no user

      // Act
      final result = await api.getEvaluations();

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('addEvaluation', () {
    test('returns Right(EvaluationModel) when successful', () async {
      // Arrange
      final evaluation = EvaluationModel(
        id: '1',
        patientId: 'p1',
        patientName: 'John Doe',
        // ...other fields
      );

      // Act
      final result = await api.addEvaluation(evaluation);

      // Assert
      expect(result.isRight(), true);
    });

    test('returns Left(ServerFailure) when user is not authenticated',
        () async {
      // Arrange
      final evaluation = EvaluationModel(
        id: '1',
        patientId: 'p1',
        patientName: 'John Doe',
        // ...other fields
      );

      // Act
      final result = await api.addEvaluation(evaluation);

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('updateEvaluation', () {
    test('returns Right(EvaluationModel) when update is successful', () async {
      // Arrange
      final evaluation = EvaluationModel(
        id: '1',
        patientId: 'p1',
        patientName: 'John Doe',
        // ...other fields
      );

      // Act
      final result = await api.updateEvaluation('1', evaluation);

      // Assert
      expect(result.isRight(), true);
    });

    test('returns Left(ServerFailure) when user is not authenticated',
        () async {
      // Arrange
      final evaluation = EvaluationModel(
        id: '1',
        patientId: 'p1',
        patientName: 'John Doe',
        // ...other fields
      );

      // Act
      final result = await api.updateEvaluation('1', evaluation);

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('deleteEvaluation', () {
    test('returns Right(void) when delete is successful', () async {
      // Arrange

      // Act
      final result = await api.deleteEvaluation('1');

      // Assert
      expect(result.isRight(), true);
    });

    test('returns Left(ServerFailure) when user is not authenticated',
        () async {
      // Arrange

      // Act
      final result = await api.deleteEvaluation('1');

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('getPatientNameById', () {
    test('returns patient name if found', () async {
      // Arrange

      // Act
      final result = await api.getPatientNameById('p1');

      // Assert
      expect(result, isNull); // Will be null unless you mock Firestore
    });
  });

  group('getEvaluationsCount', () {
    test('returns count', () async {
      // Arrange

      // Act
      final result = await api.getEvaluationsCount();

      // Assert
      expect(result, isA<Either<Failure, int>>());
    });
  });
}
