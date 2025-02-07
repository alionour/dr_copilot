import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc for handling authentication events and states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Constructor for AuthBloc, initializing with the initial state.
  AuthBloc() : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Sets the authentication persistence.
  Future<void> _setAuthPersistence() async {
    try {
      await _firebaseAuth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint('Failed to set auth persistence: $e');
    }
  }

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
      if (googleSignIn.currentUser != null) {
        emit(AuthSignedIn());
        _setAuthPersistence();
      }
      // add(GetCalendarEvents());
    } catch (error) {
      emit(AuthError(message: error.toString()));
      debugPrint(error.toString());
    }
  }

  final googleSignIn = GoogleSignInHelper();

  /// Handles native Google sign-in for Android and iOS.
  Future<void> _nativeGoogleSignIn() async {
    final googleUser = await googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }

  /// Handles web Google sign-in.
  Future<void> _webGoogleSignIn() async {
    final googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw 'Google sign-in aborted';
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
  }
}
