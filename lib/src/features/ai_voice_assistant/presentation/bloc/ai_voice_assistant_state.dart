part of 'ai_voice_assistant_bloc.dart';

abstract class AiVoiceAssistantState extends Equatable {
  final List<String> conversationHistory;
  final String recognizedText;

  const AiVoiceAssistantState(
      {this.conversationHistory = const [], this.recognizedText = ''});

  @override
  List<Object> get props => [conversationHistory, recognizedText];
}

class AiVoiceAssistantInitial extends AiVoiceAssistantState {
  const AiVoiceAssistantInitial({super.conversationHistory});
}

class AiVoiceAssistantIdle extends AiVoiceAssistantState {
  const AiVoiceAssistantIdle({super.conversationHistory, super.recognizedText});
}

class AiVoiceAssistantListening extends AiVoiceAssistantState {
  const AiVoiceAssistantListening(
      {super.conversationHistory, super.recognizedText});
}

class AiVoiceAssistantProcessing extends AiVoiceAssistantState {
  const AiVoiceAssistantProcessing(
      {super.conversationHistory, super.recognizedText});
}

class AiVoiceAssistantSpeaking extends AiVoiceAssistantState {
  final String textToSpeak;

  const AiVoiceAssistantSpeaking(this.textToSpeak,
      {super.conversationHistory, super.recognizedText});

  @override
  List<Object> get props => [textToSpeak, conversationHistory, recognizedText];
}

class AiVoiceAssistantSuccess extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantSuccess(this.message,
      {super.conversationHistory, super.recognizedText});

  @override
  List<Object> get props => [message, conversationHistory, recognizedText];
}

class AiVoiceAssistantError extends AiVoiceAssistantState {
  final String message;

  const AiVoiceAssistantError(this.message,
      {super.conversationHistory, super.recognizedText});

  @override
  List<Object> get props => [message, conversationHistory, recognizedText];
}
