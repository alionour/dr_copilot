import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc for handling authentication events and states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();

  /// Constructor for AuthBloc, initializing with the initial state.
  AuthBloc() : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
    on<SignInWithGoogleAllPlatforms>(_signInWithGoogleAllPlatforms);
  }

  final supabase = Supabase.instance.client;

  /// Handles the SignInWithGoogle event.
  ///
  /// @param event The event to sign in with Google.
  /// @param emit The function to emit states.
  void _signInWithGoogle(
      SignInWithGoogle event, Emitter<AuthState> emit) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await _nativeGoogleSignIn();
      } else {
        await _webGoogleSignIn();
      }

      // Check if the user is already signed in before navigating
      if (_googleSignInHelper.currentUser != null) {
        emit(AuthSignedIn());
      }
      // add(GetCalendarEvents());
    } catch (error) {
      emit(AuthError(message: error.toString()));
      debugPrint(error.toString());
    }
  }

  /// Handles native Google sign-in for Android and iOS.
  Future<void> _nativeGoogleSignIn() async {
    final googleUser = await _googleSignInHelper.signIn();
    final googleAuth = await googleUser!.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Handles web Google sign-in.
  Future<void> _webGoogleSignIn() async {
    final googleUser = await _googleSignInHelper.signIn();

    if (googleUser == null) {
      throw 'Google sign-in aborted';
    }

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    print('accessToken is $accessToken');

    if (accessToken == null) {
      throw 'No Access Token found.';
    }

    // await supabase.auth.signInWithOAuth(
    //   OAuthProvider.google,
    // );
  }

  /// Handles the SignInWithGoogleAllPlatforms event.
  ///
  /// @param event The event to sign in with Google on all platforms.
  /// @param emit The function to emit states.
  void _signInWithGoogleAllPlatforms(
      SignInWithGoogleAllPlatforms event, Emitter<AuthState> emit) async {
    try {
      final account = await _googleSignInHelper.signInAllPlatforms();
      if (account != null) {
        emit(AuthSignedIn());
      } else {
        emit(const AuthError(message: 'Google sign-in aborted'));
      }
    } catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }
}
