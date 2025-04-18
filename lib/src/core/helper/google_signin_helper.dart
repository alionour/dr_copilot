import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as google_sign_in_all_platforms;
import 'package:googleapis/calendar/v3.dart';
import 'package:http/http.dart';
import 'package:universal_io/io.dart' as io;
import 'dart:io';

final scopes = [
  'profile',
  'email',
  'openid',
  CalendarApi.calendarScope,
  CalendarApi.calendarEventsScope,
  CalendarApi.calendarReadonlyScope,
  CalendarApi.calendarEventsReadonlyScope,
  CalendarApi.calendarSettingsReadonlyScope
];

/// Helper class for Google Sign-In.
class GoogleSignInHelper {
  static final GoogleSignInHelper _instance = GoogleSignInHelper._internal();

  /// Factory constructor to return the singleton instance.
  factory GoogleSignInHelper() => _instance;

  /// Internal constructor to initialize the singleton instance.
  GoogleSignInHelper._internal() {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _client = await _googleSignIn.authenticatedClient();
      debugPrint('User signed in: $account'); // Add this line for debugging
    });
  }

  final google_sign_in_all_platforms.GoogleSignIn _googleSignInAllPlatforms =
      google_sign_in_all_platforms.GoogleSignIn(
    params: google_sign_in_all_platforms.GoogleSignInParams(
        clientId: Platform.environment['GOOGLE_CLIENT_ID']!,
        clientSecret: Platform.environment['GOOGLE_CLIENT_SECRET']!,
        redirectPort: int.parse(Platform.environment['REDIRECT_PORT']!),
        scopes: scopes
        // Ensure this matches the registered redirect URI
        ),
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: Platform.environment['GOOGLE_CLIENT_ID']!, scopes: scopes);
  late Client? _client;

  /// Getter for the authenticated client.
  Client? get client => _client;

  /// Signs out the current user.
  ///
  /// This method signs out the current user from Google Sign-In and prints a debug message.
  Future<void> signOut() async {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      await _googleSignInAllPlatforms.signOut();
    } else {
      await _googleSignIn.signOut();
    }
    debugPrint('User signed out'); // Add this line for debugging
  }

  /// Stream to listen for authentication state changes.
  ///
  /// This stream emits events whenever the authentication state changes.
  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Signs in the user and returns the account.
  ///
  /// This method signs in the user using Google Sign-In and returns the account.
  /// If an error occurs, it prints a debug message and returns null.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      debugPrint('User signed in: $account'); // Add this line for debugging

      return account;
    } catch (error) {
      debugPrint('Sign in error: $error');
      return null;
    }
  }

  /// Signs in the user on all platforms and returns the account.
  ///
  /// This method signs in the user on all platforms using Google Sign-In and returns the credentials.
  /// If an error occurs, it prints a debug message and returns null.
  Future<google_sign_in_all_platforms.GoogleSignInCredentials?>
      signInAllPlatforms() async {
    try {
      google_sign_in_all_platforms.GoogleSignInCredentials? credentials =
          await _googleSignInAllPlatforms.signInOnline();
      if (credentials != null) {
        _client = await _googleSignInAllPlatforms.authenticatedClient;
      }

      debugPrint('User signed in: $credentials'); // Add this line for debugging
      return credentials;
    } catch (error) {
      debugPrint('Sign in error: $error');
      return null;
    }
  }

  /// Getter for the ID token of the current user.
  ///
  /// This method returns the ID token of the current user.
  /// If the user is not signed in, it returns null.
  Future<String?> get idToken async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.idToken;
  }

  /// Getter for the access token of the current user.
  ///
  /// This method returns the access token of the current user.
  /// If the user is not signed in, it returns null.
  Future<String?> get accessToken async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.accessToken;
  }

  /// Refreshes the access token if it has expired.
  Future<String?> refreshAccessToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint('No user is currently signed in.');
        return null;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        debugPrint('Access token is null, attempting to refresh.');
        await _googleSignIn.signInSilently();
        final refreshedAuth = await account.authentication;
        debugPrint('Access token refreshed: ${refreshedAuth.accessToken}');
        return refreshedAuth.accessToken;
      }

      debugPrint('Access token is still valid: ${auth.accessToken}');
      return auth.accessToken;
    } catch (error) {
      debugPrint('Error refreshing access token: $error');
      return null;
    }
  }
}
