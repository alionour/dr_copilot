part of 'copilot_bloc.dart';

@immutable
abstract class CopilotState {}

class CopilotInitial extends CopilotState {}

class CopilotLoading extends CopilotState {}

class CopilotResponseGenerated extends CopilotState {
  final Object response;

  CopilotResponseGenerated({required this.response});
}

class CopilotError extends CopilotState {
  final String error;

  CopilotError({required this.error});
}
