import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/teams/domain/models/custom_team_model.dart';

abstract class TeamsEvent extends Equatable {
  const TeamsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamsEvent extends TeamsEvent {
  final String clinicId;

  const LoadTeamsEvent({required this.clinicId});

  @override
  List<Object?> get props => [clinicId];
}

class CreateTeamEvent extends TeamsEvent {
  final CustomTeamModel team;

  const CreateTeamEvent({required this.team});

  @override
  List<Object?> get props => [team];
}

class UpdateTeamEvent extends TeamsEvent {
  final CustomTeamModel team;

  const UpdateTeamEvent({required this.team});

  @override
  List<Object?> get props => [team];
}

class ArchiveTeamEvent extends TeamsEvent {
  final String teamId;

  const ArchiveTeamEvent({required this.teamId});

  @override
  List<Object?> get props => [teamId];
}

class UnarchiveTeamEvent extends TeamsEvent {
  final String teamId;

  const UnarchiveTeamEvent({required this.teamId});

  @override
  List<Object?> get props => [teamId];
}
