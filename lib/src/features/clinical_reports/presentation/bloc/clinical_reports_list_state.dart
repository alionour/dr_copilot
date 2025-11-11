import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:googleapis/drive/v3.dart' as drive;

abstract class ClinicalReportsListState extends Equatable {
  const ClinicalReportsListState();

  @override
  List<Object> get props => [];
}

class ClinicalReportsListInitial extends ClinicalReportsListState {}

class ClinicalReportsListLoading extends ClinicalReportsListState {}

class ClinicalReportsListLoaded extends ClinicalReportsListState {
  final List<ClinicalReport> reports;
  final Map<String, PatientModel> patients;
  final List<drive.File> driveFiles;
  final bool isFromDrive;

  const ClinicalReportsListLoaded({
    required this.reports,
    required this.patients,
    this.driveFiles = const [],
    this.isFromDrive = false,
  });

  @override
  List<Object> get props => [reports, patients, driveFiles, isFromDrive];
}

class ClinicalReportsListError extends ClinicalReportsListState {
  final String message;

  const ClinicalReportsListError(this.message);

  @override
  List<Object> get props => [message];
}
