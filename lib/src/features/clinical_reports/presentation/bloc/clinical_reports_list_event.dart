
import 'package:equatable/equatable.dart';
import 'package:googleapis/drive/v3.dart' as drive;

abstract class ClinicalReportsListEvent extends Equatable {
  const ClinicalReportsListEvent();

  @override
  List<Object> get props => [];
}

class LoadClinicalReportsList extends ClinicalReportsListEvent {}

class LoadClinicalReportsFromDrive extends ClinicalReportsListEvent {
  final List<drive.File> driveFiles;

  const LoadClinicalReportsFromDrive(this.driveFiles);

  @override
  List<Object> get props => [driveFiles];
}
