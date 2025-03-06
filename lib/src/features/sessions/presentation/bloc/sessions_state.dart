abstract class SessionsState {}

class SessionsInitial extends SessionsState {}

class SessionsLoading extends SessionsState {}

class SessionsLoaded extends SessionsState {
  // Add properties to hold session data
}

class SessionsError extends SessionsState {
  final String message;

  SessionsError(this.message);
}
