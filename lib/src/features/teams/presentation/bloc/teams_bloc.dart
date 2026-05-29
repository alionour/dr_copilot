import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
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

    result.fold(
      (failure) => emit(TeamsError(message: failure.message)),
      (teams) {
        var filteredTeams = event.showArchived
            ? teams.where((team) => team.isArchived).toList()
            : teams.where((team) => !team.isArchived).toList();

        // By default, every user only sees teams they are a member of.
        // No permission is required for this — it is the universal baseline.
        // Only users with viewTeams OR manageTeams get a global view of ALL clinic teams.
        final currentUser = FirebaseAuth.instance.currentUser;
        final hasGlobalAccess =
            OwnerNotifier().hasPermission(AppPermission.viewTeams) ||
            OwnerNotifier().hasPermission(AppPermission.manageTeams);

        if (!hasGlobalAccess && currentUser != null) {
          filteredTeams = filteredTeams
              .where((team) => team.memberIds.contains(currentUser.uid))
              .toList();
        }

        emit(TeamsLoaded(teams: filteredTeams));
      },
    );
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

