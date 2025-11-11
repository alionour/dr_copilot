part of 'sessions_bloc.dart';

/// Base state class for sessions, holding a list of [SessionModel]s.
abstract class SessionsState extends Equatable {
  /// The list of sessions.
  final List<SessionModel> sessions;

  /// Creates a [SessionsState] with the given [sessions].
  const SessionsState(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// State representing the initial state of sessions.
class SessionsInitial extends SessionsState {
  /// Creates an initial sessions state with the given [sessions].
  const SessionsInitial(super.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// State representing that sessions are currently loading.
class SessionsLoading extends SessionsState {
  /// Creates a loading state with the given [sessions].
  const SessionsLoading(super.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// State representing that more sessions are being loaded (pagination).
class SessionsLoadingMore extends SessionsState {
  /// Creates a loading more state with the given [sessions].
  const SessionsLoadingMore(super.sessions);

  @override
  List<Object?> get props => [sessions];
}

/// State representing that sessions have been loaded.
class SessionsLoaded extends SessionsState {
  /// Indicates if more sessions are being loaded.
  final bool isLoadingMore;

  /// Creates a loaded state with the given [sessions] and [isLoadingMore] flag.
  const SessionsLoaded(super.sessions, {this.isLoadingMore = false});

  @override
  List<Object> get props => [sessions, isLoadingMore];
}

/// State representing an error that occurred while handling sessions.
class SessionsError extends SessionsState {
  /// The error message, if any.
  final String? message;

  /// Creates an error state with the given [sessions] and optional [message].
  const SessionsError(super.sessions, {this.message});

  @override
  List<Object?> get props => [sessions, message];
}

/// State representing a successful operation related to sessions.
class SessionsSuccess extends SessionsState {
  /// The success message, if any.
  final String? message;

  /// Creates a success state with the given [sessions] and optional [message].
  const SessionsSuccess(super.sessions, {this.message});

  @override
  List<Object?> get props => [sessions, message];
}

/// State representing that a session type has been detected.
class SessionTypeDetected extends SessionsState {
  /// The detected session type.
  final SessionType sessionType;

  /// Creates a state with the detected [sessionType].
  const SessionTypeDetected(this.sessionType) : super(const []);

  @override
  List<Object?> get props => [sessionType];
}

/// State representing that the count of sessions has been loaded.
class SessionsCountLoaded extends SessionsState {
  /// The total count of sessions.
  final int count;

  /// Creates a state with the loaded [count] and [sessions].
  const SessionsCountLoaded(this.count, super.sessions);

  @override
  List<Object?> get props => [count, sessions];
}
