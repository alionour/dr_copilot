part of 'ai_voice_assistant_bloc.dart';

import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

abstract class AiVoiceAssistantState extends Equatable {
  final List<String> conversationHistory;
  final String recognizedText;
  final Command? partialCommand;

  const AiVoiceAssistantState({
    this.conversationHistory = const [],
    this.recognizedText = '',
    this.partialCommand,
  });

  @override
  List<Object?> get props => [conversationHistory, recognizedText, partialCommand];
}

class AiVoiceAssistantInitial extends AiVoiceAssistantState {
  const AiVoiceAssistantInitial({super.conversationHistory, super.partialCommand});
}

class AiVoiceAssistantIdle extends AiVoiceAssistantState {
  const AiVoiceAssistantIdle({super.conversationHistory, super.recognizedText, super.partialCommand});
}

class AiVoiceAssistantListening extends AiVoiceAssistantState {
  const AiVoiceAssistantListening(
      {super.conversationHistory, super.recognizedText, super.partialCommand});
}

class AiVoiceAssistantProcessing extends AiVoiceAssistantState {
  const AiVoiceAssistantProcessing(
      {super.conversationHistory, super.recognizedText, super.partialCommand});
}

class AiVoiceAssistantSpeaking extends AiVoiceAssistantState {
  final String textToSpeak;

  const AiVoiceAssistantSpeaking(this.textToSpeak,
      {super.conversationHistory, super.recognizedText, super.partialCommand});

  @override
  List<Object?> get props => [textToSpeak, conversationHistory, recognizedText, partialCommand];
}

class AiVoiceAssistantSuccess extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantSuccess(this.message,
      {super.conversationHistory, super.recognizedText, super.partialCommand});

  @override
  List<Object?> get props => [message, conversationHistory, recognizedText, partialCommand];
}

class AiVoiceAssistantCommandConfirmation extends AiVoiceAssistantState {
  final Command command;

  const AiVoiceAssistantCommandConfirmation(this.command,
      {super.conversationHistory, super.recognizedText, super.partialCommand});

  @override
  List<Object?> get props => [command, conversationHistory, recognizedText, partialCommand];
}

class AiVoiceAssistantAskingForInformation extends AiVoiceAssistantState {
  final String question;

  const AiVoiceAssistantAskingForInformation(this.question,
      {super.conversationHistory, super.recognizedText, super.partialCommand});

  @override
  List<Object?> get props => [question, conversationHistory, recognizedText, partialCommand];
}

class AiVoiceAssistantPatientSelection extends AiVoiceAssistantState {
  final List<PatientModel> patients;

  const AiVoiceAssistantPatientSelection(this.patients,
      {super.conversationHistory, super.recognizedText, super.partialCommand});

  @override
  List<Object?> get props => [patients, conversationHistory, recognizedText, partialCommand];
}

class AiVoiceAssistantError extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantError(this.message,
      {super.conversationHistory, super.recognizedText, super.partialCommand});

  @override
  List<Object?> get props => [message, conversationHistory, recognizedText, partialCommand];
}
