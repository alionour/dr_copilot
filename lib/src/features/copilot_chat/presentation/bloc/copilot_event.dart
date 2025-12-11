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

  const GenerateResponseEvent({
    required this.query,
    this.messageHistory = const [],
    this.clinicId,
    this.userId,
  });

  @override
  List<Object> get props => [
    query,
    messageHistory,
    clinicId ?? '',
    userId ?? '',
  ];
}

class UploadImageEvent extends CopilotEvent {
  final Uint8List imageBytes;
  final String text;
  final String? clinicId;
  final String? userId;

  const UploadImageEvent({
    required this.imageBytes,
    required this.text,
    this.clinicId,
    this.userId,
  });

  @override
  List<Object> get props => [imageBytes, text, clinicId ?? '', userId ?? ''];
}

class CacheMessagesEvent extends CopilotEvent {
  final List<Map<String, dynamic>> messages;

  const CacheMessagesEvent(this.messages);

  @override
  List<Object> get props => [messages];
}

class LoadCachedMessagesEvent extends CopilotEvent {}

class StartNewChatEvent extends CopilotEvent {}
