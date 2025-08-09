part of 'ai_voice_assistant_bloc.dart';

import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

abstract class AiVoiceAssistantState extends Equatable {
  final List<String> conversationHistory;
  final String recognizedText;
  final Command? partialCommand;
  final Command? originalCommand;

  const AiVoiceAssistantState({
    this.conversationHistory = const [],
    this.recognizedText = '',
    this.partialCommand,
    this.originalCommand,
  });

  @override
  List<Object?> get props => [conversationHistory, recognizedText, partialCommand, originalCommand];
}

class AiVoiceAssistantInitial extends AiVoiceAssistantState {
  const AiVoiceAssistantInitial({super.conversationHistory, super.partialCommand, super.originalCommand});
}

class AiVoiceAssistantIdle extends AiVoiceAssistantState {
  const AiVoiceAssistantIdle({super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});
}

class AiVoiceAssistantListening extends AiVoiceAssistantState {
  const AiVoiceAssistantListening(
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});
}

class AiVoiceAssistantProcessing extends AiVoiceAssistantState {
  const AiVoiceAssistantProcessing(
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});
}

class AiVoiceAssistantSpeaking extends AiVoiceAssistantState {
  final String textToSpeak;

  const AiVoiceAssistantSpeaking(this.textToSpeak,
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});

  @override
  List<Object?> get props => [textToSpeak, conversationHistory, recognizedText, partialCommand, originalCommand];
}

class AiVoiceAssistantSuccess extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantSuccess(this.message,
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});

  @override
  List<Object?> get props => [message, conversationHistory, recognizedText, partialCommand, originalCommand];
}

class AiVoiceAssistantCommandConfirmation extends AiVoiceAssistantState {
  final Command command;

  const AiVoiceAssistantCommandConfirmation(this.command,
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});

  @override
  List<Object?> get props => [command, conversationHistory, recognizedText, partialCommand, originalCommand];
}

class AiVoiceAssistantAskingForInformation extends AiVoiceAssistantState {
  final String question;

  const AiVoiceAssistantAskingForInformation(this.question,
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});

  @override
  List<Object?> get props => [question, conversationHistory, recognizedText, partialCommand, originalCommand];
}

class AiVoiceAssistantPatientSelection extends AiVoiceAssistantState {
  final List<PatientModel> patients;

  const AiVoiceAssistantPatientSelection(this.patients,
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});

  @override
  List<Object?> get props => [patients, conversationHistory, recognizedText, partialCommand, originalCommand];
}

class AiVoiceAssistantError extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantError(this.message,
      {super.conversationHistory, super.recognizedText, super.partialCommand, super.originalCommand});

  @override
  List<Object?> get props => [message, conversationHistory, recognizedText, partialCommand, originalCommand];
}
