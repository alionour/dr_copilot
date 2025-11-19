import 'package:bloc/bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:dr_copilot/src/core/services/fcm_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:get_it/get_it.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc for handling authentication events and states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Constructor for AuthBloc, initializing with the initial state.
  AuthBloc(
    this.authUseCase,
  ) : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
    on<SignInWithEmailAndPassword>(_signInWithEmailAndPassword);
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
        // Initialize FCM for the user
        await _initializeFCM(user.uid);
        
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

  /// Handles the SignInWithEmailAndPassword event.
  ///
  /// @param event The event to sign in with email and password.
  /// @param emit The function to emit states.
  void _signInWithEmailAndPassword(
      SignInWithEmailAndPassword event, Emitter<AuthState> emit) async {
    try {
      debugPrint('SignInWithEmailAndPassword event triggered');
      final user = await authUseCase.signInWithEmailAndPassword(
          event.email, event.password);
      if (user != null) {
        // Initialize FCM for the user
        await _initializeFCM(user.uid);
        
        emit(AuthSignedIn(
            message: 'User signed in successfully', userId: user.uid));
      } else {
        emit(const AuthError(message: 'Sign-in failed'));
      }
    } catch (error) {
      emit(AuthError(message: error.toString()));
      debugPrint('Email/password sign-in error: $error');
    }
  }

  /// Initialize FCM service for the user
  Future<void> _initializeFCM(String userId) async {
    try {
      final fcmService = GetIt.instance<FCMService>();
      await fcmService.initialize(userId);
      debugPrint('[AuthBloc] FCM initialized for user: $userId');
    } catch (e) {
      debugPrint('[AuthBloc] Error initializing FCM: $e');
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
