import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_instruction.dart';

abstract class AddEditClinicalReportEvent extends Equatable {
  const AddEditClinicalReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadSavedInstructions extends AddEditClinicalReportEvent {
  @override
  List<Object?> get props => [];
}

class SaveInstruction extends AddEditClinicalReportEvent {
  final ClinicalReportInstruction instruction;

  const SaveInstruction(this.instruction);

  @override
  List<Object?> get props => [instruction];
}

class DeleteInstruction extends AddEditClinicalReportEvent {
  final String instructionId;

  const DeleteInstruction(this.instructionId);

  @override
  List<Object?> get props => [instructionId];
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
  final String? clinicalData;

  const AIEditRequested(
    this.instruction,
    this.currentContent, {
    this.clinicalData,
  });

  @override
  List<Object?> get props => [instruction, currentContent, clinicalData];
}

class AIEditAccepted extends AddEditClinicalReportEvent {}

class AIEditRejected extends AddEditClinicalReportEvent {}

class AISelectionEditRequested extends AddEditClinicalReportEvent {
  final String selection;
  final String instruction;
  final String? clinicalData;

  const AISelectionEditRequested(
    this.selection,
    this.instruction, {
    this.clinicalData,
  });

  @override
  List<Object?> get props => [selection, instruction, clinicalData];
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

class AIGenerateContentRequested extends AddEditClinicalReportEvent {
  final String instruction;
  final String? clinicalData;

  const AIGenerateContentRequested(this.instruction, {this.clinicalData});

  @override
  List<Object?> get props => [instruction, clinicalData];
}

class AIClearGeneratedContent extends AddEditClinicalReportEvent {}

class AIRefineInstructionRequested extends AddEditClinicalReportEvent {
  final String text;

  const AIRefineInstructionRequested(this.text);

  @override
  List<Object?> get props => [text];
}

class AIRefineClinicalDataRequested extends AddEditClinicalReportEvent {
  final String text;

  const AIRefineClinicalDataRequested(this.text);

  @override
  List<Object?> get props => [text];
}

class AIRefineConsumed extends AddEditClinicalReportEvent {}

class SaveClinicalReportWithGoogleDoc extends AddEditClinicalReportEvent {
  final ClinicalReport report;
  final String googleDocId;

  const SaveClinicalReportWithGoogleDoc(this.report, this.googleDocId);

  @override
  List<Object> get props => [report, googleDocId];
}

class FinalizeClinicalReport extends AddEditClinicalReportEvent {
  final String reportId;

  const FinalizeClinicalReport(this.reportId);

  @override
  List<Object> get props => [reportId];
}
