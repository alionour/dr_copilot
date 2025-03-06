part of 'sessions_bloc.dart';

abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object> get props => [];
}

class LoadSessions extends SessionsEvent {}

class AddSession extends SessionsEvent {
  final Map<String, dynamic> sessionData;

  const AddSession(this.sessionData);

  @override
  List<Object> get props => [sessionData];
}

class UpdateSession extends SessionsEvent {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const UpdateSession(this.sessionId, this.sessionData);

  @override
  List<Object> get props => [sessionId, sessionData];
}

class DeleteSession extends SessionsEvent {
  final String sessionId;

  const DeleteSession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
}
