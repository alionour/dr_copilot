import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

abstract class ClinicalReportDetailsState extends Equatable {
  const ClinicalReportDetailsState();

  @override
  List<Object> get props => [];
}

class ClinicalReportDetailsInitial extends ClinicalReportDetailsState {}

class ClinicalReportDetailsLoading extends ClinicalReportDetailsState {}

class ClinicalReportDetailsLoaded extends ClinicalReportDetailsState {
  final ClinicalReport report;
  final PatientModel patient;
  final List<drive.File> documents;
  final String? contentJson;
  final String? exportStatus; // 'loading', 'success', 'error'
  final String? exportUrl;
  final String? exportError;

  const ClinicalReportDetailsLoaded(
      {required this.report,
      required this.patient,
      required this.documents,
      this.contentJson,
      this.exportStatus,
      this.exportUrl,
      this.exportError});

  ClinicalReportDetailsLoaded copyWith({
    ClinicalReport? report,
    PatientModel? patient,
    List<drive.File>? documents,
    String? contentJson,
    String? exportStatus,
    String? exportUrl,
    String? exportError,
  }) {
    return ClinicalReportDetailsLoaded(
      report: report ?? this.report,
      patient: patient ?? this.patient,
      documents: documents ?? this.documents,
      contentJson: contentJson ?? this.contentJson,
      exportStatus:
          exportStatus, // Don't persist status by default unless passed
      exportUrl: exportUrl,
      exportError: exportError,
    );
  }

  @override
  List<Object> get props => [
        report,
        patient,
        documents,
        if (contentJson != null) contentJson!,
        if (exportStatus != null) exportStatus!,
        if (exportUrl != null) exportUrl!,
        if (exportError != null) exportError!
      ];
}

class ClinicalReportDetailsError extends ClinicalReportDetailsState {
  final String message;

  const ClinicalReportDetailsError(this.message);

  @override
  List<Object> get props => [message];
}
