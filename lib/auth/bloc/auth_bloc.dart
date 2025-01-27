import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/routing/routing_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<SignInWithGoogle>(_signInWithGoogle);
  }

  void _signInWithGoogle(
      SignInWithGoogle event, Emitter<AuthState> emit) async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _nativeGoogleSignIn();
      } else {
        _webGoogleSignIn();
      }
      
      emit(AuthInitial());
      router.go('/home');

    } catch (error) {
      debugPrint(error.toString());
    }
  }

  void _nativeGoogleSignIn() async {
    final supabase = Supabase.instance.client;

    /// Web Client ID that you registered with Google Cloud.
    const webClientId =
        '991809114105-7st6rs7ntt1a8j2rdp8iveffjhobsn93.apps.googleusercontent.com';

    /// iOS Client ID that you registered with Google Cloud.
    const iosClientId =
        '991809114105-gjmdi9v4bjvhbh11a3khbb3ah1606fqb.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
    final googleUser = await googleSignIn.signIn();
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

  void _webGoogleSignIn() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
    );
  }
}
