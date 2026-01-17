import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/clinical_reports/data/remote/clinical_report_firebase_api.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockClinicalReportFirebaseApi extends Mock
    implements ClinicalReportFirebaseApi {}

class MockClinicalReport extends Mock implements ClinicalReport {}

class FakeClinicalReport extends Fake implements ClinicalReport {}

void main() {
  late ClinicalReportService service;
  late MockClinicalReportFirebaseApi mockApi;

  setUpAll(() {
    registerFallbackValue(FakeClinicalReport());
  });

  setUp(() {
    mockApi = MockClinicalReportFirebaseApi();
    service = ClinicalReportService(api: mockApi);
  });

  group('ClinicalReportService', () {
    final tReport = MockClinicalReport();
    final tReports = [tReport];

    test('getAllClinicalReports delegates to API', () async {
      when(() => mockApi.getAllReports())
          .thenAnswer((_) async => Right(tReports));

      final result = await service.getAllClinicalReports();

      verify(() => mockApi.getAllReports()).called(1);
      expect(result.isRight(), true);
    });

    test('createClinicalReport delegates to API', () async {
      when(() => mockApi.saveReport(
              report: any(named: 'report'), jsonFile: any(named: 'jsonFile')))
          .thenAnswer((_) async => Right(tReport));

      final result = await service.createClinicalReport(tReport);

      verify(() => mockApi.saveReport(report: tReport)).called(1);
      expect(result.isRight(), true);
    });

    test('updateClinicalReport delegates to API', () async {
      when(() => mockApi.saveReport(report: any(named: 'report')))
          .thenAnswer((_) async => Right(tReport));

      final result = await service.updateClinicalReport(tReport);

      verify(() => mockApi.saveReport(report: tReport)).called(1);
      expect(result.isRight(), true);
    });

    test('deleteClinicalReport delegates to API', () async {
      const id = '123';
      when(() => mockApi.deleteReport(id))
          .thenAnswer((_) async => const Right(null));

      final result = await service.deleteClinicalReport(id);

      verify(() => mockApi.deleteReport(id)).called(1);
      expect(result.isRight(), true);
    });
  });
}
