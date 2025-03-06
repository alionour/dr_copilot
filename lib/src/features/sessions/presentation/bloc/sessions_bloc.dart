import 'package:flutter_bloc/flutter_bloc.dart';
import 'sessions_event.dart';
import 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  SessionsBloc() : super(SessionsInitial()) {
    on<LoadSessions>((event, emit) async {
      emit(SessionsLoading());
      try {
        // Fetch session data and emit SessionsLoaded
        emit(SessionsLoaded());
      } catch (e) {
        emit(SessionsError(e.toString()));
      }
    });
  }
}
