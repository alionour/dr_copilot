import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/teams/domain/models/custom_team_model.dart';

abstract class TeamsState extends Equatable {
  const TeamsState();

  @override
  List<Object?> get props => [];
}

class TeamsInitial extends TeamsState {}

class TeamsLoading extends TeamsState {}

class TeamsLoaded extends TeamsState {
  final List<CustomTeamModel> teams;

  const TeamsLoaded({required this.teams});

  @override
  List<Object?> get props => [teams];
}

class TeamsError extends TeamsState {
  final String message;

  const TeamsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class TeamOperationSuccess extends TeamsState {
  final String message;

  const TeamOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
