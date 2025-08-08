part of 'ai_voice_assistant_bloc.dart';

abstract class AiVoiceAssistantEvent extends Equatable {
  const AiVoiceAssistantEvent();

  @override
  List<Object> get props => [];
}

class StartListeningEvent extends AiVoiceAssistantEvent {}

class StopListeningEvent extends AiVoiceassistantEvent {}

class TextChangedEvent extends AiVoiceAssistantEvent {
  final String text;

  const TextChangedEvent(this.text);

  @override
  List<Object> get props => [text];
}

class ProcessCommandEvent extends AiVoiceAssistantEvent {
  final String command;

  const ProcessCommandEvent(this.command);

  @override
  List<Object> get props => [command];
}

class AddMessageToHistoryEvent extends AiVoiceAssistantEvent {
  final String message;

  const AddMessageToHistoryEvent(this.message);

  @override
  List<Object> get props => [message];
}
