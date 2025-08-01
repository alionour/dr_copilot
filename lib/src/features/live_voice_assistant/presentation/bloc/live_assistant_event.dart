part of 'live_assistant_bloc.dart';

/// Base class for all live assistant events
abstract class LiveAssistantEvent extends Equatable {
  const LiveAssistantEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the live assistant
class InitializeLiveAssistantEvent extends LiveAssistantEvent {
  final String userId;
  final String? selectedAiModel;

  const InitializeLiveAssistantEvent({
    required this.userId,
    this.selectedAiModel,
  });

  @override
  List<Object?> get props => [userId, selectedAiModel];
}

/// Event to start a new voice session
class StartVoiceSessionEvent extends LiveAssistantEvent {
  final String userId;
  final String? title;
  final String? selectedAiModel;

  const StartVoiceSessionEvent({
    required this.userId,
    this.title,
    this.selectedAiModel,
  });

  @override
  List<Object?> get props => [userId, title, selectedAiModel];
}

/// Event to end the current voice session
class EndVoiceSessionEvent extends LiveAssistantEvent {
  final String sessionId;

  const EndVoiceSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Event to start listening for voice input
class StartListeningEvent extends LiveAssistantEvent {
  const StartListeningEvent();
}

/// Event to stop listening for voice input
class StopListeningEvent extends LiveAssistantEvent {
  const StopListeningEvent();
}

/// Event to cancel listening
class CancelListeningEvent extends LiveAssistantEvent {
  const CancelListeningEvent();
}

/// Event when voice input is received
class VoiceInputReceivedEvent extends LiveAssistantEvent {
  final String input;

  const VoiceInputReceivedEvent(this.input);

  @override
  List<Object?> get props => [input];
}

/// Event to process text input (manual text input)
class ProcessTextInputEvent extends LiveAssistantEvent {
  final String input;

  const ProcessTextInputEvent(this.input);

  @override
  List<Object?> get props => [input];
}

/// Event to speak AI response
class SpeakResponseEvent extends LiveAssistantEvent {
  final String text;

  const SpeakResponseEvent(this.text);

  @override
  List<Object?> get props => [text];
}

/// Event to stop speaking
class StopSpeakingEvent extends LiveAssistantEvent {
  const StopSpeakingEvent();
}

/// Event to pause speaking
class PauseSpeakingEvent extends LiveAssistantEvent {
  const PauseSpeakingEvent();
}

/// Event to resume speaking
class ResumeSpeakingEvent extends LiveAssistantEvent {
  const ResumeSpeakingEvent();
}

/// Event to execute an action
class ExecuteActionEvent extends LiveAssistantEvent {
  final AssistantActionModel action;

  const ExecuteActionEvent(this.action);

  @override
  List<Object?> get props => [action];
}

/// Event to confirm an action
class ConfirmActionEvent extends LiveAssistantEvent {
  final String actionId;

  const ConfirmActionEvent(this.actionId);

  @override
  List<Object?> get props => [actionId];
}

/// Event to cancel an action
class CancelActionEvent extends LiveAssistantEvent {
  final String actionId;

  const CancelActionEvent(this.actionId);

  @override
  List<Object?> get props => [actionId];
}

/// Event to change AI model
class ChangeAiModelEvent extends LiveAssistantEvent {
  final String modelName;

  const ChangeAiModelEvent(this.modelName);

  @override
  List<Object?> get props => [modelName];
}

/// Event to change voice settings
class ChangeVoiceSettingsEvent extends LiveAssistantEvent {
  final String? voiceId;
  final double? speechRate;
  final double? pitch;

  const ChangeVoiceSettingsEvent({
    this.voiceId,
    this.speechRate,
    this.pitch,
  });

  @override
  List<Object?> get props => [voiceId, speechRate, pitch];
}

/// Event to load session history
class LoadSessionHistoryEvent extends LiveAssistantEvent {
  final String userId;

  const LoadSessionHistoryEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Event to load a specific session
class LoadSessionEvent extends LiveAssistantEvent {
  final String sessionId;

  const LoadSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Event to delete a session
class DeleteSessionEvent extends LiveAssistantEvent {
  final String sessionId;

  const DeleteSessionEvent(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Event to toggle mute
class ToggleMuteEvent extends LiveAssistantEvent {
  const ToggleMuteEvent();
}

/// Event to clear conversation
class ClearConversationEvent extends LiveAssistantEvent {
  const ClearConversationEvent();
}

/// Event when an error occurs
class ErrorOccurredEvent extends LiveAssistantEvent {
  final String errorMessage;

  const ErrorOccurredEvent(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Event to reset the assistant state
class ResetAssistantEvent extends LiveAssistantEvent {
  const ResetAssistantEvent();
}

/// Event for real-time speech recognition updates
class SpeechRecognitionUpdateEvent extends LiveAssistantEvent {
  final String partialText;
  final bool isFinal;

  const SpeechRecognitionUpdateEvent({
    required this.partialText,
    required this.isFinal,
  });

  @override
  List<Object?> get props => [partialText, isFinal];
}

/// Event to update session context
class UpdateSessionContextEvent extends LiveAssistantEvent {
  final Map<String, dynamic> context;

  const UpdateSessionContextEvent(this.context);

  @override
  List<Object?> get props => [context];
}

/// Event to request microphone permission
class RequestMicrophonePermissionEvent extends LiveAssistantEvent {
  const RequestMicrophonePermissionEvent();
}

/// Event to check microphone permission
class CheckMicrophonePermissionEvent extends LiveAssistantEvent {
  const CheckMicrophonePermissionEvent();
}
