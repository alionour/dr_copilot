import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

abstract class AddEditClinicalReportState extends Equatable {
  const AddEditClinicalReportState();

  @override
  List<Object> get props => [];
}

class AddEditClinicalReportInitial extends AddEditClinicalReportState {}

class AddEditClinicalReportLoading extends AddEditClinicalReportState {}

class AddEditClinicalReportLoaded extends AddEditClinicalReportState {
  final ClinicalReport? report;
  final List<PatientModel> patients;

  const AddEditClinicalReportLoaded({this.report, required this.patients});

  @override
  List<Object> get props => [if (report != null) report!, patients];
}

class AddEditClinicalReportSuccess extends AddEditClinicalReportState {}

class AddEditClinicalReportError extends AddEditClinicalReportState {
  final String message;

  const AddEditClinicalReportError(this.message);

  @override
  List<Object> get props => [message];
}
