part of 'copilot_bloc.dart';

abstract class CopilotState extends Equatable {
  const CopilotState();

  @override
  List<Object> get props => [];
}

class CopilotInitial extends CopilotState {}

class CopilotLoading extends CopilotState {}

class CopilotResponseGenerated extends CopilotState {
  final dynamic response;

  const CopilotResponseGenerated(this.response);

  @override
  List<Object> get props => [response];
}

class CopilotError extends CopilotState {
  final String error;

  const CopilotError(this.error);

  @override
  List<Object> get props => [error];
}

class CachedMessagesLoaded extends CopilotState {
  final List<Map<String, dynamic>> messages;

  const CachedMessagesLoaded(this.messages);

  @override
  List<Object> get props => [messages];
}

class CopilotFunctionCall extends CopilotState {
  final FunctionCall functionCall;

  const CopilotFunctionCall(this.functionCall);

  @override
  List<Object> get props => [functionCall];
}

class NewChatStarted extends CopilotState {}

class CopilotGenerationStopped extends CopilotState {}
