library sessions_bloc;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionsUseCase _sessionsUseCase;

  SessionsBloc(this._sessionsUseCase) : super(SessionsInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<AddSession>(_onAddSession);
    on<UpdateSession>(_onUpdateSession);
    on<DeleteSession>(_onDeleteSession);
    add(LoadSessions());
  }

  void _onLoadSessions(LoadSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    try {
      final sessions = await _sessionsUseCase.getSessions();
      if (sessions.isNotEmpty) {
        debugPrint('Sessions fetched: ${sessions.length}');
        emit(SessionsLoaded(sessions));
      } else {
        debugPrint('No sessions found');
        emit(const SessionsLoaded([]));
      }
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      emit(const SessionsError('Failed to load sessions'));
    }
  }

  void _onAddSession(AddSession event, Emitter<SessionsState> emit) async {
    try {
      await _sessionsUseCase.addSession(event.model);
    } catch (e) {
      debugPrint('Error adding session: $e');
      emit(const SessionsError('Failed to add session'));
    }
  }

  void _onUpdateSession(
      UpdateSession event, Emitter<SessionsState> emit) async {
    try {
      await _sessionsUseCase.updateSession(event.model);
    } catch (e) {
      debugPrint('Error updating session: $e');
      emit(const SessionsError('Failed to update session'));
    }
  }

  void _onDeleteSession(
      DeleteSession event, Emitter<SessionsState> emit) async {
    try {
      await _sessionsUseCase.deleteSession(event.sessionId);
    } catch (e) {
      debugPrint('Error deleting session: $e');
      emit(const SessionsError('Failed to delete session'));
    }
  }
}
