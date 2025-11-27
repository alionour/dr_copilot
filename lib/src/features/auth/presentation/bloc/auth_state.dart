part of 'auth_bloc.dart';

/// An abstract base class representing the authentication state in the application.
///
/// This class extends [Equatable] to enable value-based equality comparison for its subclasses.
/// All authentication state classes should inherit from [AuthState].
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Represents the initial state of the authentication process.
///
/// This state is typically used when the authentication flow has just started
/// and no actions have been performed yet.
class AuthInitial extends AuthState {
  /// Initial state of the authentication process.
  /// This state is emitted when the authentication BLoC is first created.
  const AuthInitial();

  @override
  List<Object> get props => [];
}

/// Represents the state when a user has successfully signed in.
///
/// This state can be used to trigger UI updates or logic that should occur
/// after authentication is complete.
class AuthSignedOut extends AuthState {
  /// State emitted when the user is successfully signed out.
  /// This state indicates that the user has been logged out of the application.
  const AuthSignedOut();

  @override
  List<Object> get props => [];
}

/// Represents an authentication error state.
///
/// This state is emitted when an error occurs during the authentication process.
/// It can be used to display error messages or handle authentication failures in the UI.
class AuthError extends AuthState {
  /// A message associated with the authentication state, typically used for
  /// displaying error or status information to the user.
  final String? message;

  const AuthError({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSignedIn extends AuthState {
  final String message;
  final UserModel? user;

  const AuthSignedIn({required this.message, this.user});

  @override
  List<Object?> get props => [message, user];
}

/// Represents the state when an authentication process is in progress.
///
/// This state is typically used to show a loading indicator in the UI.
class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object> get props => [];
}
