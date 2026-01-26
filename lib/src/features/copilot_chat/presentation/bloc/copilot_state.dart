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
  final String? usedModel;

  const CopilotResponseGenerated(this.response, {this.usedModel});

  @override
  List<Object> get props => [response, usedModel ?? ''];
}

class CopilotError extends CopilotState {
  final String error;

  const CopilotError(this.error);

  @override
  List<Object> get props => [error];
}

class CachedMessagesLoaded extends CopilotState {
  final List<Map<String, dynamic>> messages;
  final String? conversationId;

  const CachedMessagesLoaded(this.messages, {this.conversationId});

  @override
  List<Object> get props => [messages, conversationId ?? ''];
}

class CopilotFunctionCall extends CopilotState {
  final FunctionCall functionCall;
  final String? usedModel;

  const CopilotFunctionCall(this.functionCall, {this.usedModel});

  @override
  List<Object> get props => [functionCall, usedModel ?? ''];
}

/// State for Groq function calls
class CopilotGroqFunctionCall extends CopilotState {
  final GroqFunctionCall functionCall;
  final String? usedModel;

  const CopilotGroqFunctionCall(this.functionCall, {this.usedModel});

  @override
  List<Object> get props => [functionCall, usedModel ?? ''];
}

class CopilotFormRequested extends CopilotState {
  final String formType;
  final Map<String, dynamic> initialData;
  final String? usedModel;

  const CopilotFormRequested(this.formType, this.initialData, {this.usedModel});

  @override
  List<Object> get props => [formType, initialData, usedModel ?? ''];
}

class NewChatStarted extends CopilotState {}

class CopilotGenerationStopped extends CopilotState {}
