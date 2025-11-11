part of 'auth_bloc.dart';

/// Base class for all authentication-related events.
///
/// Extend this class to define specific authentication events
/// that can be dispatched to the authentication BLoC.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override

  /// Returns a list of properties that will be used to determine whether two instances are equal.
  /// Override this getter to include all the fields that should be considered for equality comparison.
  List<Object> get props => [];
}

/// Event triggered to initiate the sign-in process using Google authentication.
class SignInWithGoogle extends AuthEvent {
  /// Constructor for the SignInWithGoogle event.
  ///
  /// This event is dispatched when the user requests to sign in using Google authentication.
  const SignInWithGoogle();

  @override
  List<Object> get props => [];
}

/// Event triggered to initiate the sign-out process for the user.
///
/// This event should be dispatched when the user requests to log out
/// from the application. It is handled by the authentication BLoC
/// to perform necessary sign-out operations.
class SignOutEvent extends AuthEvent {
  /// Constructor for the SignOutEvent.
  ///
  /// This event is dispatched when the user requests to sign out from the application.
  const SignOutEvent();

  @override
  List<Object> get props => [];
}
