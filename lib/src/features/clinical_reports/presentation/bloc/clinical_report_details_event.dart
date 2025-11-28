import 'package:equatable/equatable.dart';

abstract class ClinicalReportDetailsEvent extends Equatable {
  const ClinicalReportDetailsEvent();

  @override
  List<Object> get props => [];
}

class LoadClinicalReportDetails extends ClinicalReportDetailsEvent {
  final String reportId;

  const LoadClinicalReportDetails(this.reportId);

  @override
  List<Object> get props => [reportId];
}

class ExportClinicalReportToGoogleDocs extends ClinicalReportDetailsEvent {
  final String reportId;
  final String contentJson;

  const ExportClinicalReportToGoogleDocs(this.reportId, this.contentJson);

  @override
  List<Object> get props => [reportId, contentJson];
}
