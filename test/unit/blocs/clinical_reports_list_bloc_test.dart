import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_state.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockClinicalReportService extends Mock implements ClinicalReportService {}

class MockPatientService extends Mock implements PatientService {}

class MockClinicalReport extends Mock implements ClinicalReport {
  @override
  String get patientId => 'patient123';
}

class MockPatientModel extends Mock implements PatientModel {}

void main() {
  late MockClinicalReportService mockReportService;
  late MockPatientService mockPatientService;

  setUp(() {
    mockReportService = MockClinicalReportService();
    mockPatientService = MockPatientService();
  });

  group('ClinicalReportsListBloc', () {
    final tReport = MockClinicalReport();
    final tReports = [tReport];
    final tPatient = MockPatientModel();

    blocTest<ClinicalReportsListBloc, ClinicalReportsListState>(
      'emits [ClinicalReportsListLoading, ClinicalReportsListLoaded] when LoadClinicalReportsList succeeds',
      build: () {
        when(() => mockReportService.getAllClinicalReports())
            .thenAnswer((_) async => Right(tReports));
        when(() => mockPatientService.getPatient(any()))
            .thenAnswer((_) async => Right(tPatient)); // Mock patient fetch
        return ClinicalReportsListBloc(mockReportService, mockPatientService);
      },
      act: (bloc) => bloc.add(LoadClinicalReportsList()),
      expect: () => [
        ClinicalReportsListLoading(),
        isA<ClinicalReportsListLoaded>(), // Verify loaded state
      ],
    );

    blocTest<ClinicalReportsListBloc, ClinicalReportsListState>(
      'emits [ClinicalReportsListLoading, ClinicalReportsListError] when LoadClinicalReportsList fails',
      build: () {
        when(() => mockReportService.getAllClinicalReports())
            .thenAnswer((_) async => Left(ServerFailure('Error', 500)));
        return ClinicalReportsListBloc(mockReportService, mockPatientService);
      },
      act: (bloc) => bloc.add(LoadClinicalReportsList()),
      expect: () => [
        ClinicalReportsListLoading(),
        isA<ClinicalReportsListError>(),
      ],
    );
  });
}
