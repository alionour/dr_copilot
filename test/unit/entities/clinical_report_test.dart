import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

void main() {
  const tReportId = '123';
  const tPatientId = 'patient123';
  const tTitle = 'Test Report';
  const tDescription = 'Test Description';
  final tDate = DateTime.now();

  final tReport = ClinicalReport(
    id: tReportId,
    patientId: tPatientId,
    title: tTitle,
    description: tDescription,
    date: tDate,
    documentUrls: const ['url1', 'url2'],
    isFinalized: false,
  );

  group('ClinicalReport Entity', () {
    test('props should contain all fields', () {
      expect(tReport.props, [
        tReportId,
        tPatientId,
        tTitle,
        tDescription,
        tDate,
        ['url1', 'url2'],
        null, // contentUrl
        null, // content
        null, // googleDocId
        false, // isFinalized
        null, // finalizedAt
        null, // finalizedBy
      ]);
    });

    test('copyWith should return a copy with updated fields', () {
      final updatedReport =
          tReport.copyWith(title: 'Updated Title', isFinalized: true);

      expect(updatedReport.title, 'Updated Title');
      expect(updatedReport.isFinalized, true);
      expect(updatedReport.id, tReportId); // Unchanged
    });
  });
}
