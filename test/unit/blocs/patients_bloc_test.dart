import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPatientsUseCase extends Mock implements PatientsUseCase {}

class MockPatientModel extends Mock implements PatientModel {
  @override
  String get id => '123';
  @override
  Timestamp? get createdAt => Timestamp.now();
}

class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

class FakePatientModel extends Fake implements PatientModel {}

void main() {
  late MockPatientsUseCase mockPatientsUseCase;

  setUpAll(() {
    registerFallbackValue(FakePatientModel());
  });

  setUp(() {
    mockPatientsUseCase = MockPatientsUseCase();
  });

  group('PatientsBloc', () {
    final tPatient = MockPatientModel();
    final tPatientsList = [tPatient];
    final tLastDoc = MockDocumentSnapshot();

    blocTest<PatientsBloc, PatientsState>(
      'emits [PatientsLoading, PatientsLoaded] when GetPatients succeeds',
      build: () {
        when(
          () => mockPatientsUseCase.getPatients(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Right(Tuple2(tPatientsList, tLastDoc)));
        return PatientsBloc(mockPatientsUseCase);
      },
      act: (bloc) => bloc.add(const GetPatients()),
      expect: () => [
        const PatientsLoading([]),
        PatientsLoaded(tPatientsList, lastDocument: tLastDoc),
      ],
    );

    blocTest<PatientsBloc, PatientsState>(
      'emits [PatientsLoading, PatientsError] when GetPatients fails',
      build: () {
        when(
          () => mockPatientsUseCase.getPatients(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Left(ServerFailure('Error', 500)));
        return PatientsBloc(mockPatientsUseCase);
      },
      act: (bloc) => bloc.add(const GetPatients()),
      expect: () => [const PatientsLoading([]), isA<PatientsError>()],
    );

    blocTest<PatientsBloc, PatientsState>(
      'emits [PatientsLoading, PatientsSuccess, PatientsLoaded] when AddPatient succeeds',
      build: () {
        when(
          () => mockPatientsUseCase.addPatient(any()),
        ).thenAnswer((_) async => Right(tPatient));
        return PatientsBloc(mockPatientsUseCase);
      },
      act: (bloc) => bloc.add(AddPatient(tPatient)),
      expect: () => [
        const PatientsLoading([]),
        isA<PatientsSuccess>(), // 'patientAddedSuccessfully'.tr()
        isA<PatientsLoaded>(),
      ],
    );
  });
}
