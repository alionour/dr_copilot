// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPatientFirebaseApi extends Mock implements PatientFirebaseApi {}

class MockPatientModel extends Mock implements PatientModel {}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

class FakePatientModel extends Fake implements PatientModel {}

void main() {
  late PatientsRepositoryImpl repository;
  late MockPatientFirebaseApi mockApi;

  setUpAll(() {
    registerFallbackValue(FakePatientModel());
  });

  setUp(() {
    mockApi = MockPatientFirebaseApi();
    repository = PatientsRepositoryImpl(mockApi);
  });

  group('PatientsRepositoryImpl', () {
    final tPatient = MockPatientModel();
    final tPatients = [tPatient];
    final tLastDoc = MockDocumentSnapshot();

    test('getPatients delegates to API', () async {
      when(
        () => mockApi.getPatients(limit: any(named: 'limit')),
      ).thenAnswer((_) async => Right(Tuple2(tPatients, tLastDoc)));

      final result = await repository.getPatients(limit: 10);

      verify(() => mockApi.getPatients(limit: 10)).called(1);
      expect(result.isRight(), true);
    });

    test('addPatient delegates to API', () async {
      when(
        () => mockApi.addPatient(any()),
      ).thenAnswer((_) async => Right(tPatient));

      final result = await repository.addPatient(tPatient);

      verify(() => mockApi.addPatient(tPatient)).called(1);
      expect(result.isRight(), true);
    });

    test('deletePatient delegates to API', () async {
      const id = '123';
      when(
        () => mockApi.deletePatient(id),
      ).thenAnswer((_) async => const Right(null));

      final result = await repository.deletePatient(id);

      verify(() => mockApi.deletePatient(id)).called(1);
      expect(result.isRight(), true);
    });
  });
}
