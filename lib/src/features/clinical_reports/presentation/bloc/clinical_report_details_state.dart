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

  const ClinicalReportDetailsLoaded(
      {required this.report, required this.patient, required this.documents});

  @override
  List<Object> get props => [report, patient, documents];
}

class ClinicalReportDetailsError extends ClinicalReportDetailsState {
  final String message;

  const ClinicalReportDetailsError(this.message);

  @override
  List<Object> get props => [message];
}
