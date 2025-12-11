import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_event.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_state.dart';

class TeamsBloc extends Bloc<TeamsEvent, TeamsState> {
  final AbstractCustomTeamsRepository repository;

  TeamsBloc({required this.repository}) : super(TeamsInitial()) {
    on<LoadTeamsEvent>(_onLoadTeams);
    on<CreateTeamEvent>(_onCreateTeam);
    on<UpdateTeamEvent>(_onUpdateTeam);
    on<ArchiveTeamEvent>(_onArchiveTeam);
    on<UnarchiveTeamEvent>(_onUnarchiveTeam);
  }

  Future<void> _onLoadTeams(
    LoadTeamsEvent event,
    Emitter<TeamsState> emit,
  ) async {
    emit(TeamsLoading());

    final result = await repository.getTeamsForClinic(event.clinicId);

    result.fold((failure) => emit(TeamsError(message: failure.message)), (
      teams,
    ) {
      // Filter out archived teams
      final activeTeams = teams.where((team) => !team.isArchived).toList();
      emit(TeamsLoaded(teams: activeTeams));
    });
  }

  Future<void> _onCreateTeam(
    CreateTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    final result = await repository.createTeam(event.team);

    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (_) => emit(
        const TeamOperationSuccess(message: 'Team created successfully'),
      ),
    );
  }

  Future<void> _onUpdateTeam(
    UpdateTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    final result = await repository.updateTeam(event.team);

    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (_) => emit(
        const TeamOperationSuccess(message: 'Team updated successfully'),
      ),
    );
  }

  Future<void> _onArchiveTeam(
    ArchiveTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    final result = await repository.archiveTeam(event.teamId);

    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (_) => emit(
        const TeamOperationSuccess(message: 'Team archived successfully'),
      ),
    );
  }

  Future<void> _onUnarchiveTeam(
    UnarchiveTeamEvent event,
    Emitter<TeamsState> emit,
  ) async {
    final result = await repository.unarchiveTeam(event.teamId);

    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (_) => emit(
        const TeamOperationSuccess(message: 'Team unarchived successfully'),
      ),
    );
  }
}
