import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

/// Helper class for Google Sign-In.
class GoogleSignInHelper {
  static final GoogleSignInHelper _instance = GoogleSignInHelper._internal();

  /// Factory constructor to return the singleton instance.
  factory GoogleSignInHelper() => _instance;

  /// Internal constructor to initialize the singleton instance.
  GoogleSignInHelper._internal() {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _client = await _googleSignIn.authenticatedClient();
    });
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId:
          '991809114105-7st6rs7ntt1a8j2rdp8iveffjhobsn93.apps.googleusercontent.com',
      scopes: [
        'profile',
        'email',
        'openid',
        CalendarApi.calendarScope,
        CalendarApi.calendarEventsScope,
        CalendarApi.calendarReadonlyScope,
        CalendarApi.calendarEventsReadonlyScope,
        CalendarApi.calendarSettingsReadonlyScope
      ]);
  late AuthClient? _client;

  /// Getter for the authenticated client.
  AuthClient? get client => _client;

  /// Signs out the current user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Getter for the current signed-in user.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Stream to listen for authentication state changes.
  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Signs in the user and returns the account.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      return account;
    } catch (error) {
      print('Sign in error: $error');
      return null;
    }
  }

  /// Getter for the ID token of the current user.
  Future<String?> get idToken async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.idToken;
  }

  /// Getter for the access token of the current user.
  Future<String?> get accessToken async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.accessToken;
  }
}
