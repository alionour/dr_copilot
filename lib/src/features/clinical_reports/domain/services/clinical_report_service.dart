import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:collection/collection.dart';

class ClinicalReportService {
  final List<ClinicalReport> _reports = []; // In-memory storage for mock data

  // For generating unique IDs
  int _nextId = 1;

  Future<ClinicalReport> createClinicalReport(ClinicalReport newReport) async {
    final reportWithId = newReport.copyWith(id: 'report_${_nextId++}');
    _reports.add(reportWithId);
    return reportWithId;
  }

  Future<ClinicalReport?> getClinicalReport(String reportId) async {
    return _reports.firstWhereOrNull((c) => c.id == reportId);
  }

  Future<List<ClinicalReport>> getClinicalReportsForPatient(
      String patientId) async {
    return _reports.where((c) => c.patientId == patientId).toList();
  }

  Future<ClinicalReport?> updateClinicalReport(
      ClinicalReport updatedReport) async {
    final index = _reports.indexWhere((c) => c.id == updatedReport.id);
    if (index != -1) {
      _reports[index] = updatedReport;
      return updatedReport;
    }
    return null;
  }

  Future<void> deleteClinicalReport(String reportId) async {
    _reports.removeWhere((c) => c.id == reportId);
  }

  Future<List<ClinicalReport>> getAllClinicalReports() async {
    return _reports;
  }
}
