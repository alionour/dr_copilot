library sessions_bloc;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionsUseCase _sessionsUseCase;

  SessionsBloc(this._sessionsUseCase) : super(SessionsInitial()) {
    on<GetSessions>(_onGetSessions);
    on<AddSession>(_onAddSession);
    on<UpdateSession>(_onUpdateSession);
    on<DeleteSession>(_onDeleteSession);
  }

  void _onGetSessions(GetSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    final failureOrSessions = await _sessionsUseCase.getSessions(event.query);
    emit(failureOrSessions.fold(
      (failure) => SessionsError(message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onAddSession(AddSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    final failureOrSession = await _sessionsUseCase.addSession(event.model);
    emit(failureOrSession.fold(
      (failure) => SessionsError(message: _mapFailureToMessage(failure)),
      (session) {
        emit(const SessionsSuccess(message: 'Session added successfully'));
        return SessionsLoaded([session]);
      },
    ));
  }

  void _onUpdateSession(
      UpdateSession event, Emitter<SessionsState> emit) async {
    final failureOrSession =
        await _sessionsUseCase.updateSession(event.sessionId, event.model);
    failureOrSession.fold(
      (failure) {
        final errorMessage = _mapFailureToMessage(failure);
        debugPrint('Update failed: $errorMessage');
        emit(SessionsError(message: errorMessage));
      },
      (updatedSession) {
        debugPrint('Update successful: $updatedSession');
        if (state is SessionsLoaded) {
          // Update the list of sessions locally
          final currentSessions = (state as SessionsLoaded).sessions;
          final updatedSessions = currentSessions.map((session) {
            return session.id == updatedSession.id ? updatedSession : session;
          }).toList();

          // Emit the updated list of sessions
          emit(SessionsLoaded(updatedSessions));
        } else {
          // If no sessions are loaded, emit success without refreshing
          emit(const SessionsSuccess(message: 'Session updated successfully'));
        }
      },
    );
  }

  Future<void> _onDeleteSession(
      DeleteSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading());
    final failureOrSession =
        await _sessionsUseCase.deleteSession(event.sessionId);
    failureOrSession.fold(
      (failure) => emit(SessionsError(message: _mapFailureToMessage(failure))),
      (deletedSession) {
        debugPrint('Delete successful: $deletedSession');
        if (state is SessionsLoaded) {
          // Update the list of sessios locally
          final currentSessions = (state as SessionsLoaded).sessions;
          final updatedSessions = currentSessions.map((session) {
            return session.id == deletedSession.id ? deletedSession : session;
          }).toList();
          // Emit the updated list of sessions
          emit(SessionsLoaded(updatedSessions));
        } else {
          // If no sessions are loaded, emit success without refreshing
          emit(const SessionsSuccess(message: 'Patient deleted successfully'));
        }
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server Failure: ${failure.message}';
      case CacheFailure _:
        return 'Cache Failure: ${failure.message}';
      default:
        return 'Unexpected Error: ${failure.message}';
    }
  }
}
