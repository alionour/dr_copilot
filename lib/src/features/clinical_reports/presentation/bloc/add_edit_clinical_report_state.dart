import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_chat_message.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_instruction.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

abstract class AddEditClinicalReportState extends Equatable {
  const AddEditClinicalReportState();

  @override
  List<Object?> get props => [];
}

class AddEditClinicalReportInitial extends AddEditClinicalReportState {}

class AddEditClinicalReportLoading extends AddEditClinicalReportState {}

class AddEditClinicalReportLoaded extends AddEditClinicalReportState {
  final ClinicalReport? report;
  final List<PatientModel> patients;
  final String? contentJson;
  final String? originalContent;
  final bool isReviewingAIChanges;
  final bool isAILoading;
  final List<ClinicalReportInstruction> instructions;
  final List<ClinicalReportChatMessage> chatMessages;
  final String? pendingAISelectionEdit;
  final String? pendingAIInsert;

  final String? generatedContent;
  final String? refinedInstruction;
  final String? refinedClinicalData;

  const AddEditClinicalReportLoaded({
    required this.patients,
    this.report,
    this.contentJson,
    this.isAILoading = false,
    this.isReviewingAIChanges = false,
    this.originalContent,
    this.instructions = const [],
    this.chatMessages = const [],
    this.pendingAISelectionEdit,
    this.pendingAIInsert,
    this.generatedContent,
    this.refinedInstruction,
    this.refinedClinicalData,
  });

  @override
  List<Object?> get props => [
    patients,
    report,
    contentJson,
    isAILoading,
    isReviewingAIChanges,
    originalContent,
    instructions,
    chatMessages,
    pendingAISelectionEdit,
    pendingAIInsert,
    generatedContent,
    refinedInstruction,
    refinedClinicalData,
  ];

  AddEditClinicalReportLoaded copyWith({
    List<PatientModel>? patients,
    ClinicalReport? report,
    String? contentJson,
    bool? isAILoading,
    bool? isReviewingAIChanges,
    String? originalContent,
    List<ClinicalReportInstruction>? instructions,
    List<ClinicalReportChatMessage>? chatMessages,
    String? pendingAISelectionEdit,
    String? pendingAIInsert,
    String? generatedContent,
    String? refinedInstruction,
    String? refinedClinicalData,
  }) {
    return AddEditClinicalReportLoaded(
      patients: patients ?? this.patients,
      report: report ?? this.report,
      contentJson: contentJson ?? this.contentJson,
      isAILoading: isAILoading ?? this.isAILoading,
      isReviewingAIChanges: isReviewingAIChanges ?? this.isReviewingAIChanges,
      originalContent: originalContent ?? this.originalContent,
      instructions: instructions ?? this.instructions,
      chatMessages: chatMessages ?? this.chatMessages,
      pendingAISelectionEdit:
          pendingAISelectionEdit ?? this.pendingAISelectionEdit,
      pendingAIInsert: pendingAIInsert ?? this.pendingAIInsert,
      generatedContent: generatedContent ?? this.generatedContent,
      refinedInstruction: refinedInstruction ?? this.refinedInstruction,
      refinedClinicalData: refinedClinicalData ?? this.refinedClinicalData,
    );
  }
}

class AddEditClinicalReportSuccess extends AddEditClinicalReportState {
  final String? reportId;

  const AddEditClinicalReportSuccess({this.reportId});

  @override
  List<Object?> get props => [reportId];
}

class AddEditClinicalReportError extends AddEditClinicalReportState {
  final String message;

  const AddEditClinicalReportError(this.message);

  @override
  List<Object?> get props => [message];
}
