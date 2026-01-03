part of 'copilot_bloc.dart';

abstract class CopilotEvent extends Equatable {
  const CopilotEvent();

  @override
  List<Object> get props => [];
}

class GenerateResponseEvent extends CopilotEvent {
  final String query;
  final List<Map<String, dynamic>> messageHistory;
  final String? clinicId;
  final String? userId;
  final bool? forcePremium;

  const GenerateResponseEvent({
    required this.query,
    this.messageHistory = const [],
    this.clinicId,
    this.userId,
    this.forcePremium,
  });

  @override
  List<Object> get props => [
        query,
        messageHistory,
        clinicId ?? '',
        userId ?? '',
        forcePremium ?? false,
      ];
}

class UploadImageEvent extends CopilotEvent {
  final Uint8List imageBytes;
  final String text;
  final String? clinicId;
  final String? userId;
  final bool? forcePremium;

  const UploadImageEvent({
    required this.imageBytes,
    required this.text,
    this.clinicId,
    this.userId,
    this.forcePremium,
  });

  @override
  List<Object> get props =>
      [imageBytes, text, clinicId ?? '', userId ?? '', forcePremium ?? false];
}

class CacheMessagesEvent extends CopilotEvent {
  final List<Map<String, dynamic>> messages;

  const CacheMessagesEvent(this.messages);

  @override
  List<Object> get props => [messages];
}

class LoadCachedMessagesEvent extends CopilotEvent {}

class StartNewChatEvent extends CopilotEvent {}

class UpdateCopilotSettingsEvent extends CopilotEvent {
  final List<String> requiredFields;
  const UpdateCopilotSettingsEvent(this.requiredFields);
  @override
  List<Object> get props => [requiredFields];
}

class StopGenerationEvent extends CopilotEvent {}
