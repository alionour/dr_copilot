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
  AuthBloc(this.authUseCase) : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
    on<SignInWithEmailAndPassword>(_signInWithEmailAndPassword);
    on<SignOutEvent>(_onSignOut);
    on<AuthCheckRequested>(_onAuthCheckRequested);
  }

  final AuthUseCase authUseCase;

  /// Handles the SignInWithGoogle event.
  ///
  /// @param event The event to sign in with Google.
  /// @param emit The function to emit states.
  /// Handles the SignInWithGoogle event.
  ///
  /// @param event The event to sign in with Google.
  /// @param emit The function to emit states.
  void _signInWithGoogle(
    SignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    debugPrint('SignInWithGoogle event triggered');
    final result = await authUseCase.signInWithGoogle();

    await result.fold(
      (failure) async {
        debugPrint('Google sign-in error: ${failure.message}');
        emit(AuthError(message: failure.message));
      },
      (user) async {
        if (user != null) {
          // Initialize FCM for the user
          await _initializeFCM(user.uid);
          emit(
              AuthSignedIn(message: 'User signed in successfully', user: user));
        } else {
          emit(const AuthError(message: 'Google sign-in aborted'));
        }
      },
    );
  }

  /// Handles the SignInWithEmailAndPassword event.
  ///
  /// @param event The event to sign in with email and password.
  /// @param emit The function to emit states.
  void _signInWithEmailAndPassword(
    SignInWithEmailAndPassword event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    debugPrint('SignInWithEmailAndPassword event triggered');
    final result = await authUseCase.signInWithEmailAndPassword(
      event.email,
      event.password,
    );

    await result.fold((failure) async {
      debugPrint('Email/password sign-in error: ${failure.message}');
      emit(AuthError(message: failure.message));
    }, (user) async {
      if (user != null) {
        // Initialize FCM for the user
        await _initializeFCM(user.uid);
        emit(AuthSignedIn(message: 'User signed in successfully', user: user));
      } else {
        emit(const AuthError(message: 'Sign-in failed'));
      }
    });
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
    debugPrint('Sign out event triggered');

    final currentUserResult = await authUseCase.getCurrentUser();

    // Attempt to clear cache for current user photo
    currentUserResult.fold((l) => null, // Ignore failure here
        (user) async {
      if (user != null && user.photoURL != null) {
        await CachedNetworkImage.evictFromCache(user.photoURL!);
      }
    });

    // Clean up FCM (delete token and stop listeners)
    try {
      final fcmService = GetIt.instance<FCMService>();
      await fcmService.deleteToken();
      debugPrint('[AuthBloc] FCM cleaned up');
    } catch (e) {
      debugPrint('[AuthBloc] Error cleaning up FCM: $e');
    }

    final signOutResult = await authUseCase.signOut();

    signOutResult.fold((failure) {
      debugPrint('Sign-out error: ${failure.message}');
      emit(AuthError(message: failure.message));
    }, (_) {
      debugPrint('Sign-out successful');
      RoutingConfig.router.go('/');
      emit(AuthSignedOut());
    });
  }

  /// Returns a stream of authentication state changes (UserModel? or null).
  Stream<UserModel?> userAuthenticationStream() {
    return authUseCase.authStateChanges();
  }

  /// Handles the AuthCheckRequested event.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    await emit.forEach(
      authUseCase.authStateChanges(),
      onData: (user) {
        if (user != null) {
          _initializeFCM(user.uid);
          return AuthSignedIn(message: 'User restored', user: user);
        }
        return AuthSignedOut();
      },
      onError: (error, stackTrace) => AuthError(message: error.toString()),
    );
  }
}
