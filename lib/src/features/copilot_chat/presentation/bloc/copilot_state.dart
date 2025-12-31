part of 'copilot_bloc.dart';

/// Abstract base class for all Copilot Chat states.
abstract class CopilotState extends Equatable {
  const CopilotState();

  @override
  List<Object> get props => [];
}

/// Initial state of the Bloc.
class CopilotInitial extends CopilotState {}

/// State indicating that the AI is processing a request.
class CopilotLoading extends CopilotState {}

/// State indicating a successful response from the AI.
class CopilotResponseGenerated extends CopilotState {
  final dynamic response;

  const CopilotResponseGenerated(this.response);

  @override
  List<Object> get props => [response];
}

/// State indicating an error occurred during request processing.
class CopilotError extends CopilotState {
  final String error;

  const CopilotError(this.error);

  @override
  List<Object> get props => [error];
}

/// State indicating that cached messages have been loaded.
class CachedMessagesLoaded extends CopilotState {
  final List<Map<String, dynamic>> messages;

  const CachedMessagesLoaded(this.messages);

  @override
  List<Object> get props => [messages];
}

/// State indicating the AI wants to execute a function call (e.g., fetch patient data).
class CopilotFunctionCall extends CopilotState {
  final FunctionCall functionCall;

  const CopilotFunctionCall(this.functionCall);

  @override
  List<Object> get props => [functionCall];
}

/// State indicating a new chat session has started.
class NewChatStarted extends CopilotState {}
