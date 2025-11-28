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

  const AddEditClinicalReportLoaded({
    this.report,
    required this.patients,
    this.contentJson,
    this.originalContent,
    this.isReviewingAIChanges = false,
    this.isAILoading = false,
    this.instructions = const [],
    this.chatMessages = const [],
    this.pendingAISelectionEdit,
    this.pendingAIInsert,
  });

  AddEditClinicalReportLoaded copyWith({
    ClinicalReport? report,
    List<PatientModel>? patients,
    String? contentJson,
    String? originalContent,
    bool? isReviewingAIChanges,
    bool? isAILoading,
    List<ClinicalReportInstruction>? instructions,
    List<ClinicalReportChatMessage>? chatMessages,
    String? pendingAISelectionEdit,
    String? pendingAIInsert,
  }) {
    return AddEditClinicalReportLoaded(
      report: report ?? this.report,
      patients: patients ?? this.patients,
      contentJson: contentJson ?? this.contentJson,
      originalContent: originalContent ?? this.originalContent,
      isReviewingAIChanges: isReviewingAIChanges ?? this.isReviewingAIChanges,
      isAILoading: isAILoading ?? this.isAILoading,
      instructions: instructions ?? this.instructions,
      chatMessages: chatMessages ?? this.chatMessages,
      pendingAISelectionEdit: pendingAISelectionEdit,
      pendingAIInsert: pendingAIInsert,
    );
  }

  @override
  List<Object?> get props => [
    report,
    patients,
    contentJson,
    originalContent,
    isReviewingAIChanges,
    isAILoading,
    instructions,
    chatMessages,
    pendingAISelectionEdit,
    pendingAIInsert,
  ];
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
