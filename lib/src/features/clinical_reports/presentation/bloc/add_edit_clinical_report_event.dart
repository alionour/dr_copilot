import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_instruction.dart';

abstract class AddEditClinicalReportEvent extends Equatable {
  const AddEditClinicalReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddEditClinicalReport extends AddEditClinicalReportEvent {
  final String? reportId;

  const LoadAddEditClinicalReport(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

class SearchPatients extends AddEditClinicalReportEvent {
  final String query;

  const SearchPatients(this.query);

  @override
  List<Object?> get props => [query];
}

class DeleteClinicalReport extends AddEditClinicalReportEvent {
  final String reportId;

  const DeleteClinicalReport(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

class AutoSaveClinicalReport extends AddEditClinicalReportEvent {
  final ClinicalReport report;
  final File? jsonFile;

  const AutoSaveClinicalReport(this.report, {this.jsonFile});

  @override
  List<Object?> get props => [report, jsonFile];
}

class SaveClinicalReport extends AddEditClinicalReportEvent {
  final ClinicalReport report;
  final File? jsonFile;

  const SaveClinicalReport(this.report, {this.jsonFile});

  @override
  List<Object> get props => [report, if (jsonFile != null) jsonFile!];
}

class AIEditRequested extends AddEditClinicalReportEvent {
  final String instruction;
  final String currentContent;

  const AIEditRequested(this.instruction, this.currentContent);

  @override
  List<Object> get props => [instruction, currentContent];
}

class AIEditAccepted extends AddEditClinicalReportEvent {}

class AIEditRejected extends AddEditClinicalReportEvent {}

class AISelectionEditRequested extends AddEditClinicalReportEvent {
  final String selection;
  final String instruction;

  const AISelectionEditRequested(this.selection, this.instruction);

  @override
  List<Object> get props => [selection, instruction];
}

class LoadInstructions extends AddEditClinicalReportEvent {
  final String userId;

  const LoadInstructions(this.userId);

  @override
  List<Object> get props => [userId];
}

class AddInstruction extends AddEditClinicalReportEvent {
  final ClinicalReportInstruction instruction;

  const AddInstruction(this.instruction);

  @override
  List<Object> get props => [instruction];
}

class DeleteInstruction extends AddEditClinicalReportEvent {
  final String userId;
  final String instructionId;

  const DeleteInstruction(this.userId, this.instructionId);

  @override
  List<Object> get props => [userId, instructionId];
}

class LoadChatHistory extends AddEditClinicalReportEvent {
  final String reportId;

  const LoadChatHistory(this.reportId);

  @override
  List<Object> get props => [reportId];
}

class SendChatMessage extends AddEditClinicalReportEvent {
  final String reportId;
  final String message;

  const SendChatMessage(this.reportId, this.message);

  @override
  List<Object> get props => [reportId, message];
}

class AISelectionEditConsumed extends AddEditClinicalReportEvent {}

class AIInsertRequested extends AddEditClinicalReportEvent {
  final String instruction;

  const AIInsertRequested(this.instruction);

  @override
  List<Object> get props => [instruction];
}

class AIInsertConsumed extends AddEditClinicalReportEvent {}
