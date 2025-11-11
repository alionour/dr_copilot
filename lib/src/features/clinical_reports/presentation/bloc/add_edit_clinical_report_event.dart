import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

abstract class AddEditClinicalReportEvent extends Equatable {
  const AddEditClinicalReportEvent();

  @override
  List<Object> get props => [];
}

class LoadAddEditClinicalReport extends AddEditClinicalReportEvent {
  final String? reportId;

  const LoadAddEditClinicalReport(this.reportId);

  @override
  List<Object> get props => [if (reportId != null) reportId!];
}

class SaveClinicalReport extends AddEditClinicalReportEvent {
  final ClinicalReport report;

  const SaveClinicalReport(this.report);

  @override
  List<Object> get props => [report];
}
