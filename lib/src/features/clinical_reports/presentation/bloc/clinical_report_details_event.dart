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
