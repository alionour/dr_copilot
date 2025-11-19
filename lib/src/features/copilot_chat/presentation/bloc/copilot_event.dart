part of 'copilot_bloc.dart';

abstract class CopilotEvent extends Equatable {
  const CopilotEvent();

  @override
  List<Object> get props => [];
}

class GenerateResponseEvent extends CopilotEvent {
  final String query;
  final String selectedModel;
  final List<Map<String, dynamic>> messageHistory;

  const GenerateResponseEvent({
    required this.query,
    required this.selectedModel,
    this.messageHistory = const [],
  });

  @override
  List<Object> get props => [query, selectedModel, messageHistory];
}

class UploadImageEvent extends CopilotEvent {
  final String selectedModel;
  final Uint8List imageBytes;
  final String text;

  const UploadImageEvent(
      {required this.selectedModel,
      required this.imageBytes,
      required this.text});

  @override
  List<Object> get props => [selectedModel, imageBytes, text];
}

class CacheMessagesEvent extends CopilotEvent {
  final List<Map<String, dynamic>> messages;

  const CacheMessagesEvent(this.messages);

  @override
  List<Object> get props => [messages];
}

class LoadCachedMessagesEvent extends CopilotEvent {}

class StartNewChatEvent extends CopilotEvent {}
