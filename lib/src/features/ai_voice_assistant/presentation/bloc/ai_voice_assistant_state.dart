part of 'ai_voice_assistant_bloc.dart';

abstract class AiVoiceAssistantState extends Equatable {
  const AiVoiceAssistantState();

  @override
  List<Object> get props => [];
}

class AiVoiceAssistantInitial extends AiVoiceAssistantState {}

class AiVoiceAssistantListening extends AiVoiceAssistantState {
  final String recognizedText;

  const AiVoiceAssistantListening(this.recognizedText);

  @override
  List<Object> get props => [recognizedText];
}

class AiVoiceAssistantProcessing extends AiVoiceAssistantState {}

class AiVoiceAssistantSpeaking extends AiVoiceAssistantState {
  final String textToSpeak;

  const AiVoiceAssistantSpeaking(this.textToSpeak);

  @override
  List<Object> get props => [textToSpeak];
}

class AiVoiceAssistantSuccess extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class AiVoiceAssistantError extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantError(this.message);

  @override
  List<Object> get props => [message];
}
