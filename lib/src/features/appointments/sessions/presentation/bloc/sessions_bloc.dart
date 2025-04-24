library;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionsUseCase _sessionsUseCase;

  SessionsBloc(this._sessionsUseCase) : super(const SessionsInitial([])) {
    on<GetSessions>(_onGetSessions);
    on<AddSession>(_onAddSession);
    on<UpdateSession>(_onUpdateSession);
    on<DeleteSession>(_onDeleteSession);
    on<SearchSessions>(_onSearchSessions);
    on<GetSessionsByDate>(_onGetSessionsByDate);
    on<LoadMoreSessions>(_onLoadMoreSessions);
    on<DetectSessionType>(_onDetectSessionType);
    on<GetSessionsCount>(_onGetSessionsCount);
  }

  void _onGetSessions(GetSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessions = await _sessionsUseCase.getSessions(
      lastDocumentID: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrSessions.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onAddSession(AddSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSession = await _sessionsUseCase.addSession(event.model);
    emit(failureOrSession.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (addedSession) {
        debugPrint('Add successful: $addedSession');
        final sessions = state.sessions..add(addedSession);
        emit(SessionsSuccess(sessions,
            message: 'sessionAddedSuccessfully'.tr()));
        return SessionsLoaded(sessions);
      },
    ));
  }

  void _onUpdateSession(
      UpdateSession event, Emitter<SessionsState> emit) async {
    final failureOrSession =
        await _sessionsUseCase.updateSession(event.sessionId, event.model);
    debugPrint(': ${event.model.toJson()}');

    emit(failureOrSession.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (updatedSession) {
        debugPrint('Update successful: ${updatedSession.toJson()}');
        final sessions = state.sessions.map((session) {
          return session.id == updatedSession.id ? updatedSession : session;
        }).toList();
        emit(
            SessionsSuccess(sessions, message: 'Session updated successfully'));
        return SessionsLoaded(sessions);
      },
    ));
  }

  Future<void> _onDeleteSession(
      DeleteSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSession =
        await _sessionsUseCase.deleteSession(event.sessionId);
    emit(failureOrSession.fold(
        (failure) => SessionsError(state.sessions,
            message: _mapFailureToMessage(failure)), (deletedSession) {
      debugPrint('Delete successful: ${event.sessionId}');
      final sessions = state.sessions
        ..removeWhere((session) => session.id == event.sessionId);
      emit(SessionsSuccess(sessions, message: 'sessionDeleted'.tr()));
      return SessionsLoaded(sessions);
    }));
  }

  Future<void> _onSearchSessions(
      SearchSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessions =
        await _sessionsUseCase.searchSessions(name: event.name);
    emit(failureOrSessions.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onGetSessionsByDate(
      GetSessionsByDate event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessions =
        await _sessionsUseCase.getSessionsByDate(event.date);
    emit(failureOrSessions.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onLoadMoreSessions(
      LoadMoreSessions event, Emitter<SessionsState> emit) async {
    if (state is SessionsLoaded) {
      final currentState = state as SessionsLoaded;
      if (currentState.isLoadingMore) return;

      emit(SessionsLoaded(currentState.sessions, isLoadingMore: true));
      await Future.delayed(Duration(seconds: 1));
      final result = await _sessionsUseCase.getSessions(
        lastDocumentID: event.lastDocumentId,
        limit: event.limit,
      );

      result.fold(
        (failure) {
          debugPrint(
              'LoadMoreSessions failed: ${_mapFailureToMessage(failure)}');
          emit(SessionsError(currentState.sessions,
              message: _mapFailureToMessage(failure)));
        },
        (newSessions) {
          debugPrint(
              'Fetched ${newSessions.length} new sessions: ${newSessions.map((s) => s.id).toList()}');
          final updatedSessions = List<SessionModel>.from(currentState.sessions)
            ..addAll(newSessions.where((newSession) => !currentState.sessions
                .any(
                    (existingSession) => existingSession.id == newSession.id)));
          debugPrint(
              'Updated sessions list contains ${updatedSessions.length} sessions.');
          emit(SessionsLoaded(updatedSessions));
        },
      );
    }
  }

  void _onDetectSessionType(
      DetectSessionType event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessionType =
        await _sessionsUseCase.detectSessionType(event.patientId);
    emit(failureOrSessionType.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessionType) => SessionTypeDetected(sessionType),
    ));
  }

  /// Handles the [GetSessionsCount] event by emitting new [SessionsState]s.
  ///
  /// This asynchronous function listens for the [GetSessionsCount] event and updates
  /// the state accordingly using the provided [Emitter]. Typically used to fetch and
  /// emit the count of sessions in the application.
  ///
  /// Parameters:
  /// - [event]: The [GetSessionsCount] event to handle.
  /// - [emit]: The function used to emit new [SessionsState]s.
  void _onGetSessionsCount(
      GetSessionsCount event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrCount = await _sessionsUseCase.getSessionsCount();
    emit(failureOrCount.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (count) {
        debugPrint('Total sessions count: $count');
        return SessionsCountLoaded(count, state.sessions);
      },
    ));
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
