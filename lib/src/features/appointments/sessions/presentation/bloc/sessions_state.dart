part of 'sessions_bloc.dart';

abstract class SessionsState extends Equatable {
  /// The list of sessions.
  final List<SessionModel> sessions;
  const SessionsState(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionsInitial extends SessionsState {
  const SessionsInitial(super.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionsLoading extends SessionsState {
  const SessionsLoading(super.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionsLoadingMore extends SessionsState {
  const SessionsLoadingMore(super.sessions);

  @override
  List<Object?> get props => [sessions];
}

class SessionsLoaded extends SessionsState {
  const SessionsLoaded(super.sessions);

  @override
  List<Object> get props => [sessions];
}

class SessionsError extends SessionsState {
  final String? message;

  const SessionsError(super.sessions, {this.message});

  @override
  List<Object?> get props => [sessions, message];
}

class SessionsSuccess extends SessionsState {
  final String? message;

  const SessionsSuccess(super.sessions, {this.message});

  @override
  List<Object?> get props => [sessions, message];
}
