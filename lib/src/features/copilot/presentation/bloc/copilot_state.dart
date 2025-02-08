part of 'copilot_bloc.dart';

abstract class CopilotState extends Equatable {
  const CopilotState();

  @override
  List<Object> get props => [];
}

class CopilotInitial extends CopilotState {}

class CopilotLoading extends CopilotState {}

class CopilotLoaded extends CopilotState {
  final List<CopilotModel> copilots;

  const CopilotLoaded(this.copilots);

  @override
  List<Object> get props => [copilots];
}

class CopilotError extends CopilotState {
  final String message;

  const CopilotError(this.message);

  @override
  List<Object> get props => [message];
}
// ...additional states...
