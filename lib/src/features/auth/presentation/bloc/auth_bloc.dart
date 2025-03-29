import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;

part 'auth_event.dart';
part 'auth_state.dart';

/// Bloc for handling authentication events and states.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Constructor for AuthBloc, initializing with the initial state.
  AuthBloc() : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
    on<SignOutEvent>(_onSignOut);
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignInHelper _googleSignInHelper = GoogleSignInHelper();

  /// Handles the SignInWithGoogle event.
  ///
  /// @param event The event to sign in with Google.
  /// @param emit The function to emit states.
  void _signInWithGoogle(
      SignInWithGoogle event, Emitter<AuthState> emit) async {
    try {
      debugPrint('SignInWithGoogle event triggered');
      late AuthState authState;
      if (io.Platform.isAndroid || io.Platform.isIOS) {
        authState = await _nativeGoogleSignIn();
      } else if (kIsWeb) {
        authState = await _webGoogleSignIn();
      } else if (io.Platform.isWindows || io.Platform.isLinux) {
        // Use google_sign_in_all_platforms for Windows and Linux
        authState = await _allPlatformsGoogleSignIn();
      }
      emit(authState);
    } catch (error) {
      emit(AuthError(message: error.toString()));
      debugPrint('Google sign-in error: $error');
    }
  }

  /// Handles native Google sign-in for Android and iOS.
  ///
  /// @return The authentication state after sign-in.
  Future<AuthState> _nativeGoogleSignIn() async {
    debugPrint('Attempting native Google sign-in');
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

    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    // Check if the user is already signed in before navigating
    if (currentUser != null) {
      debugPrint('Google sign-in successful: ${currentUser.email}');
      await _storeUserData(
          currentUser, googleAuth.accessToken, googleAuth.idToken);
      return AuthSignedIn();
    } else {
      debugPrint('Google sign-in failed: No current user');
      return const AuthError(message: 'Google sign-in failed: No current user');
    }
  }

  /// Handles web Google sign-in.
  ///
  /// @return The authentication state after sign-in.
  Future<AuthState> _webGoogleSignIn() async {
    debugPrint('Attempting web Google sign-in');
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

    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    // Check if the user is already signed in before navigating
    if (currentUser != null) {
      debugPrint('Google sign-in successful: ${currentUser.email}');
      await _storeUserData(
          currentUser, googleAuth.accessToken, googleAuth.idToken);
      return AuthSignedIn();
    } else {
      debugPrint('Google sign-in failed: No current user');
      return const AuthError(message: 'Google sign-in failed: No current user');
    }
  }

  /// Handles Google sign-in for all platforms.
  ///
  /// @return The authentication state after sign-in.
  Future<AuthState> _allPlatformsGoogleSignIn() async {
    try {
      debugPrint('Attempting Google sign-in for all platforms');
      final googleAuth = await _googleSignInHelper.signInAllPlatforms();
      debugPrint('Google sign-in successful: ${googleAuth?.accessToken}');
      if (googleAuth == null) {
        return const AuthError(message: 'Google sign-in aborted');
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _firebaseAuth.signInWithCredential(credential);
      debugPrint('All Platforms Google sign-in successful');

      final currentUser = await FirebaseAuth.instance.authStateChanges().first;
      // Check if the user is already signed in before navigating
      if (currentUser != null) {
        debugPrint('Google sign-in successful: ${currentUser.email}');
        await _storeUserData(
            currentUser, googleAuth.accessToken, googleAuth.idToken);
        return AuthSignedIn();
      } else {
        debugPrint('Google sign-in failed: No current user');
        return const AuthError(
            message: 'Google sign-in failed: No current user');
      }
    } catch (error) {
      debugPrint('Google sign-in error: $error');
      return AuthError(message: error.toString());
    }
  }

  /// Stores user data in Firestore after sign-in.
  ///
  /// @param user The signed-in user.
  /// @param accessToken The access token from Google sign-in.
  /// @param idToken The ID token from Google sign-in.
  Future<void> _storeUserData(
      User user, String? accessToken, String? idToken) async {
    debugPrint('Storing user data in Firestore for user: ${user.email}');
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.set({
      'uid': user.uid,
      'email': user.email,
      'emailVerified': user.emailVerified,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'providerData': user.providerData
          .map((provider) => {
                'displayName': provider.displayName,
                'email': provider.email,
                'photoURL': provider.photoURL,
                'providerId': provider.providerId,
                'uid': provider.uid,
              })
          .toList(),
      'metadata': {
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      },
      'accessToken': accessToken,
      'idToken': idToken,
    }, SetOptions(merge: true));
    debugPrint('User data stored successfully for user: ${user.email}');
  }

  /// Handles the SignOutEvent.
  ///
  /// @param event The event to sign out.
  /// @param emit The function to emit states.
  void _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    try {
      debugPrint('Signing out...');
      await _googleSignInHelper.signOut();
      await FirebaseAuth.instance.signOut();
      debugPrint('Sign-out successful');
      RoutingConfig.router.go('/');
      emit(AuthSignedOut());
    } catch (e) {
      debugPrint('Sign-out error: $e');
      emit(AuthError(message: e.toString()));
    }
  }
}
