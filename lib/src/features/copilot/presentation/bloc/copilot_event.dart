part of 'copilot_bloc.dart';

abstract class CopilotEvent extends Equatable {
  const CopilotEvent();

  @override
  List<Object> get props => [];
}

class GetCopilots extends CopilotEvent {}
// ...additional events...
