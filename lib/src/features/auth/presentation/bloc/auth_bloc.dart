import 'package:bloc/bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc for handling authentication events and states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Constructor for AuthBloc, initializing with the initial state.
  AuthBloc(
    this.authUseCase,
  ) : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
    on<SignOutEvent>(_onSignOut);
  }

  final AuthUseCase authUseCase;

  /// Handles the SignInWithGoogle event.
  ///
  /// @param event The event to sign in with Google.
  /// @param emit The function to emit states.
  void _signInWithGoogle(
      SignInWithGoogle event, Emitter<AuthState> emit) async {
    try {
      debugPrint('SignInWithGoogle event triggered');
      final user = await authUseCase.signInWithGoogle();
      if (user != null) {
        // Optionally store user data if needed
        emit(AuthSignedIn(
            message: 'User signed in successfully', userId: user.uid));
      } else {
        emit(const AuthError(message: 'Google sign-in aborted'));
      }
    } catch (error) {
      emit(AuthError(message: error.toString()));
      debugPrint('Google sign-in error: $error');
    }
  }

  /// Handles the SignOutEvent.
  ///
  /// @param event The event to sign out.
  /// @param emit The function to emit states.
  void _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    try {
      debugPrint('Sign out event triggered');
      final user = await authUseCase.getCurrentUser();
      if (user != null && user.photoURL != null) {
        await CachedNetworkImage.evictFromCache(user.photoURL!);
      }
      await authUseCase.signOut();
      debugPrint('Sign-out successful');
      RoutingConfig.router.go('/');
      emit(AuthSignedOut());
    } catch (e) {
      debugPrint('Sign-out error: $e');
      emit(AuthError(message: e.toString()));
    }
  }

  /// Returns a stream of authentication state changes (UserModel? or null).
  Stream<UserModel?> userAuthenticationStream() {
    return authUseCase.authStateChanges();
  }
}
