library sessions_bloc;

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/sessions/domain/usecases/sessions_usecase.dart';
import 'package:equatable/equatable.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  final SessionsUseCase _sessionsUseCase;

  SessionsBloc(this._sessionsUseCase) : super(SessionsInitial()) {
    on<LoadSessions>(_onLoadSessions);
    on<AddSession>(_onAddSession);
    on<UpdateSession>(_onUpdateSession);
    on<DeleteSession>(_onDeleteSession);
  }

  void _onLoadSessions(LoadSessions event, Emitter<SessionsState> emit) {
    emit(SessionsLoading());
    _sessionsUseCase.getSessions().listen((snapshot) {
      emit(SessionsLoaded(snapshot.docs));
    });
  }

  void _onAddSession(AddSession event, Emitter<SessionsState> emit) async {
    await _sessionsUseCase.addSession(event.sessionData);
  }

  void _onUpdateSession(
      UpdateSession event, Emitter<SessionsState> emit) async {
    await _sessionsUseCase.updateSession(event.sessionId, event.sessionData);
  }

  void _onDeleteSession(
      DeleteSession event, Emitter<SessionsState> emit) async {
    await _sessionsUseCase.deleteSession(event.sessionId);
  }
}
