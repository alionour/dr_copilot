part of 'ai_voice_assistant_bloc.dart';

abstract class AiVoiceAssistantState extends Equatable {
  final List<String> conversationHistory;
  const AiVoiceAssistantState({this.conversationHistory = const []});

  @override
  List<Object> get props => [conversationHistory];
}

class AiVoiceAssistantInitial extends AiVoiceAssistantState {
  const AiVoiceAssistantInitial({super.conversationHistory});
}

class AiVoiceAssistantListening extends AiVoiceAssistantState {
  final String recognizedText;

  const AiVoiceAssistantListening(this.recognizedText,
      {super.conversationHistory});

  @override
  List<Object> get props => [recognizedText, conversationHistory];
}

class AiVoiceAssistantProcessing extends AiVoiceAssistantState {
  const AiVoiceAssistantProcessing({super.conversationHistory});
}

class AiVoiceAssistantSpeaking extends AiVoiceAssistantState {
  final String textToSpeak;

  const AiVoiceAssistantSpeaking(this.textToSpeak, {super.conversationHistory});

  @override
  List<Object> get props => [textToSpeak, conversationHistory];
}

class AiVoiceAssistantSuccess extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantSuccess(this.message, {super.conversationHistory});

  @override
  List<Object> get props => [message, conversationHistory];
}

class AiVoiceAssistantError extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantError(this.message, {super.conversationHistory});

  @override
  List<Object> get props => [message, conversationHistory];
}
