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
    on<SignInWithGoogleAllPlatforms>(_signInWithGoogleAllPlatforms);
    _setAuthPersistence(); // Set auth persistence on initialization
    _listenToAuthStateChanges(); // Listen to auth state changes
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();

  /// Sets the authentication persistence.
  Future<void> _setAuthPersistence() async {
    try {
      if (kIsWeb) {
        await _firebaseAuth.setPersistence(Persistence.SESSION);
        debugPrint('Auth persistence set to SESSION for web');
      } else {
        await _firebaseAuth.setPersistence(Persistence.LOCAL);
        debugPrint('Auth persistence set to LOCAL');
      }
    } catch (e) {
      debugPrint('Failed to set auth persistence: $e');
    }
  }

  /// Listens to authentication state changes.
  void _listenToAuthStateChanges() {
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint('User is already signed in: ${user.email}');
        add(AuthSignedInEvent());
      } else {
        debugPrint('No user is currently signed in');
        add(AuthInitialEvent());
      }
    });
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


      final currentUser = await FirebaseAuth.instance.authStateChanges().first;
      // Check if the user is already signed in before navigating
      if ( currentUser!= null) {
        debugPrint(
            'Google sign-in successful: ${currentUser.email}');
        emit(AuthSignedIn());
      } else {
        debugPrint('Google sign-in failed: No current user');
        emit(
            const AuthError(message: 'Google sign-in failed: No current user'));
      }
      // add(GetCalendarEvents());
    } catch (error) {
      emit(AuthError(message: error.toString()));
      debugPrint('Google sign-in error: $error');
    }
  }

  /// Handles native Google sign-in for Android and iOS.
  Future<void> _nativeGoogleSignIn() async {
    
    final googleUser = await _googleSignInHelper.signIn();
    if (googleUser == null) {
      throw 'Google sign-in aborted';
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await _firebaseAuth.signInWithCredential(credential);
    debugPrint('Native Google sign-in successful');
  }

  /// Handles web Google sign-in.
  Future<void> _webGoogleSignIn() async {
    final googleUser = await _googleSignInHelper.signIn();

    if (googleUser == null) {
      throw 'Google sign-in aborted';
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
    debugPrint('Web Google sign-in successful');
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
