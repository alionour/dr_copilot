part of 'copilot_bloc.dart';

/// Abstract base class for all Copilot Chat events.
abstract class CopilotEvent extends Equatable {
  const CopilotEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when the user sends a text query.
class GenerateResponseEvent extends CopilotEvent {
  final String query;
  final List<Map<String, dynamic>> messageHistory;
  final String? clinicId;
  final String? userId;
  final bool forcePremium;

  const GenerateResponseEvent({
    required this.query,
    this.messageHistory = const [],
    this.clinicId,
    this.userId,
    this.forcePremium = false,
  });

  @override
  List<Object> get props => [
        query,
        messageHistory,
        clinicId ?? '',
        userId ?? '',
        forcePremium,
      ];
}

/// Event triggered when the user uploads an image with an optional caption.
class UploadImageEvent extends CopilotEvent {
  final Uint8List imageBytes;
  final String text;
  final String? clinicId;
  final String? userId;
  final bool forcePremium;

  const UploadImageEvent({
    required this.imageBytes,
    required this.text,
    this.clinicId,
    this.userId,
    this.forcePremium = false,
  });

  @override
  List<Object> get props =>
      [imageBytes, text, clinicId ?? '', userId ?? '', forcePremium];
}

/// Event triggered to cache the current list of messages locally.
class CacheMessagesEvent extends CopilotEvent {
  final List<Map<String, dynamic>> messages;

  const CacheMessagesEvent(this.messages);

  @override
  List<Object> get props => [messages];
}

/// Event triggered to load cached messages from local storage.
class LoadCachedMessagesEvent extends CopilotEvent {}

/// Event triggered to clear the current chat context and start a new conversation.
class StartNewChatEvent extends CopilotEvent {}

/// Event triggered when copilot settings (like model configuration) are updated.
class UpdateCopilotSettingsEvent extends CopilotEvent {
  final List<String> requiredFields;
  const UpdateCopilotSettingsEvent(this.requiredFields);
  @override
  List<Object> get props => [requiredFields];
}

/// Event triggered to regenerate the last response from the AI.
class RegenerateResponseEvent extends CopilotEvent {
  final String? clinicId;
  final String? userId;

  const RegenerateResponseEvent({this.clinicId, this.userId});

  @override
  List<Object> get props => [clinicId ?? '', userId ?? ''];
}

/// Event triggered when the user provides feedback (like/dislike) on a message.
class ProvideFeedbackEvent extends CopilotEvent {
  final String messageId;
  final bool isLike;
  final String? userId; // Added
  final String? clinicId; // Added

  const ProvideFeedbackEvent({
    required this.messageId,
    required this.isLike,
    this.userId, // Added
    this.clinicId, // Added
  });

  @override
  List<Object> get props => [messageId, isLike, userId ?? '', clinicId ?? ''];
}
