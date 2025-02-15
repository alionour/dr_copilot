part of 'copilot_bloc.dart';

@immutable
abstract class CopilotEvent {}

class GenerateResponseEvent extends CopilotEvent {
  final String query;
  final String selectedModel;

  GenerateResponseEvent({required this.query, required this.selectedModel});
}

class UploadImageEvent extends CopilotEvent {
  final String selectedModel;
  final Uint8List imageBytes;
  final String text;

  UploadImageEvent(
      {required this.selectedModel,
      required this.imageBytes,
      required this.text});
}

class StartNewChatEvent extends CopilotEvent {}
