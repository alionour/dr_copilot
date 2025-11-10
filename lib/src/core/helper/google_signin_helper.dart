import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as g_sign_in_all;
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart';
import 'package:universal_io/io.dart' as io;
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


/// A list of OAuth 2.0 scopes required for Google Sign-In and Google Calendar API access.
///
/// Includes basic user profile information (`profile`, `email`, `openid`) and various
/// Google Calendar API scopes for different levels of access:
/// - [CalendarApi.calendarScope]: Full access to the user's calendar.
/// - [CalendarApi.calendarEventsScope]: Manage the user's calendar events.
/// - [CalendarApi.calendarReadonlyScope]: Read-only access to the user's calendar.
/// - [CalendarApi.calendarEventsReadonlyScope]: Read-only access to the user's calendar events.
/// - [CalendarApi.calendarSettingsReadonlyScope]: Read-only access to the user's calendar settings.
final scopes = [
  'profile',
  'email',
  'openid',
  CalendarApi.calendarScope,
  CalendarApi.calendarEventsScope,
  CalendarApi.calendarReadonlyScope,
  CalendarApi.calendarEventsReadonlyScope,
  CalendarApi.calendarSettingsReadonlyScope,
  drive.DriveApi.driveScope
];

/// Custom AuthClient for using a saved access token with Google APIs
class AuthClient extends BaseClient {
  final String accessToken;
  final Client _inner = Client();
  final Future<String?> Function()? refreshTokenCallback;
  AuthClient(this.accessToken, {this.refreshTokenCallback});

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    String token = accessToken;
    request.headers['Authorization'] = 'Bearer $token';
    StreamedResponse response = await _inner.send(request);
    // If unauthorized, try to refresh token and retry once
    if (response.statusCode == 401 && refreshTokenCallback != null) {
      debugPrint('[AuthClient] 401 received, attempting to refresh token...');
      final newToken = await refreshTokenCallback!();
      debugPrint('[AuthClient] Token after refresh: $newToken');
      if (newToken != null && newToken != token) {
        // Clone the request for retry
        debugPrint('[AuthClient] Cloning request and retrying with new token.');
        final clonedRequest = _cloneRequest(request);
        clonedRequest.headers['Authorization'] = 'Bearer $newToken';
        return _inner.send(clonedRequest);
      } else {
        debugPrint('[AuthClient] Token refresh failed or token unchanged.');
      }
    }
    return response;
  }

  /// Helper to clone a BaseRequest (supports Request and MultipartRequest)
  BaseRequest _cloneRequest(BaseRequest request) {
    if (request is Request) {
      final cloned = Request(request.method, request.url);
      cloned.headers.addAll(request.headers);
      cloned.followRedirects = request.followRedirects;
      cloned.maxRedirects = request.maxRedirects;
      cloned.persistentConnection = request.persistentConnection;
      if (request.bodyBytes.isNotEmpty) {
        cloned.bodyBytes = request.bodyBytes;
      }
      return cloned;
    } else if (request is MultipartRequest) {
      final cloned = MultipartRequest(request.method, request.url);
      cloned.headers.addAll(request.headers);
      cloned.fields.addAll(request.fields);
      cloned.files.addAll(request.files);
      cloned.followRedirects = request.followRedirects;
      cloned.maxRedirects = request.maxRedirects;
      cloned.persistentConnection = request.persistentConnection;
      return cloned;
    } else {
      throw UnsupportedError(
          'Request type not supported for retry: \\${request.runtimeType}');
    }
  }
}

/// Helper class for Google Sign-In.
class GoogleSignInHelper {
  static final GoogleSignInHelper _instance = GoogleSignInHelper._internal();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  /// Factory constructor to return the singleton instance.
  factory GoogleSignInHelper() => _instance;

  /// Internal constructor to initialize the singleton instance.
  GoogleSignInHelper._internal() {
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _client = await _googleSignIn.authenticatedClient();
      debugPrint('User signed in: $account'); // Add this line for debugging
    });
  }

  /// Initializes a [GoogleSignIn] instance for all platforms using the provided parameters.
  ///
  /// The parameters are retrieved from environment variables:
  /// - `WEB_CLIENT_ID`: The OAuth 2.0 client ID for web.
  /// - `WEB_CLIENT_SECRET`: The OAuth 2.0 client secret for web.
  /// - `WEB_REDIRECT_PORT`: The port used for the redirect URI.
  /// - `scopes`: The list of OAuth scopes to request.
  ///
  /// Make sure the redirect URI matches the one registered in the Google API Console.
  final g_sign_in_all.GoogleSignIn _googleSignInAllPlatforms =
      g_sign_in_all.GoogleSignIn(
    params: g_sign_in_all.GoogleSignInParams(
        clientId: Platform.environment['WEB_CLIENT_ID']!,
        clientSecret: Platform.environment['WEB_CLIENT_SECRET']!,
        redirectPort: int.parse(Platform.environment['WEB_REDIRECT_PORT']!),
        scopes: scopes,
        // Ensure this matches the registered redirect URI
        ),
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
      clientId: Platform.environment['WEB_CLIENT_ID']!,
      scopes: scopes);
  Client? _client;

  /// Ensures the authenticated client is initialized and returns it.
  Future<Client?> ensureClientInitialized() async {
    try {
      if (_client == null) {
        // Try to sign in silently first to restore the GoogleSignIn session
        GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
        debugPrint('Called signInSilently for GoogleSignIn. Current user: $currentUser');

        if (currentUser != null) {
          _client = await _googleSignIn.authenticatedClient();
          debugPrint('Initialized _client from silent sign-in: $_client');
        } else if (io.Platform.isWindows || io.Platform.isLinux) {
          // Fallback for desktop platforms if silent sign-in fails
          final credentials = await _googleSignInAllPlatforms.signInOnline();
          if (credentials != null) {
            _client = await _googleSignInAllPlatforms.authenticatedClient;
            debugPrint('Initialized _client for all platforms: $_client');
          } else {
            debugPrint('No credentials returned from signInAllPlatforms.');
          }
        } else { // For other platforms (Android, iOS, Web) if silent sign-in fails
          // Prompt for interactive sign-in
          currentUser = await _googleSignIn.signIn();
          debugPrint('Called interactive signIn for GoogleSignIn. Current user: $currentUser');

          if (currentUser != null) {
            _client = await _googleSignIn.authenticatedClient();
            debugPrint('Initialized _client from interactive sign-in: $_client');
          } else {
            debugPrint('GoogleSignIn: No user signed in after silent and interactive attempts.');
          }
        }
      } else {
        debugPrint('_client already initialized: $_client');
      }
    } catch (e, stack) {
      debugPrint('Error initializing _client: $e\n$stack');
      _client = null;
    }
    return _client;
  }

  /// Asynchronous getter for the client (may be null if not initialized).
  Future<Client?> get client async {
    if (_client == null) {
      await ensureClientInitialized();
    }
    // print client when access it
    debugPrint('Accessing client: $_client');
    return _client;
  }

  /// Signs out the currently authenticated user from Google Sign-In.
  ///
  /// This method revokes the user's authentication credentials and disconnects
  /// the application from the user's Google account. After calling this method,
  /// the user will need to sign in again to access Google-protected resources.
  ///
  /// Throws an [Exception] if the sign-out process fails.
  Future<void> signOut() async {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      await _googleSignInAllPlatforms.signOut();
    } else {
      await _googleSignIn.signOut();
    }
    debugPrint('User signed out'); // Add this line for debugging
  }

  /// A stream that emits the current [GoogleSignInAccount] whenever the authentication
  /// state changes. Emits `null` if the user signs out or is not authenticated.
  ///
  /// Listen to this stream to be notified when the user's sign-in state changes.
  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;

  /// Initiates the Google sign-in process.
  ///
  /// Returns a [GoogleSignInAccount] if the sign-in is successful, or `null` if the user cancels
  /// the sign-in or an error occurs.
  ///
  /// Throws an exception if the sign-in process fails unexpectedly.
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

  /// Signs in the user using the all-platforms Google Sign-In method.
  /// Returns a [GoogleSignInCredentials] object if the sign-in is successful,
  /// or `null` if the sign-in fails or is cancelled by the user.
  ///
  /// Throws an exception if an unexpected error occurs during the sign-in process.
  Future<g_sign_in_all.GoogleSignInCredentials?> signInAllPlatforms() async {
    try {
      g_sign_in_all.GoogleSignInCredentials? credentials =
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

  /// Asynchronously retrieves the current user's Google ID token.
  ///
  /// Returns a [String] containing the ID token if the user is signed in,
  /// or `null` if no user is currently authenticated.
  ///
  /// This token can be used to authenticate requests to your backend server.
  Future<String?> get idToken async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.idToken;
  }

  /// Asynchronously retrieves the current Google access token, if available.
  ///
  /// Returns a [String] containing the access token, or `null` if no token is available.
  ///
  /// This getter is typically used to authenticate requests to Google APIs on behalf of the user.
  Future<String?> get accessToken async {
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.accessToken;
  }

  /// Refreshes the Google Sign-In access token.
  ///
  /// Returns a [String] containing the new access token if successful,
  /// or `null` if the token could not be refreshed.
  ///
  /// Throws an exception if an error occurs during the refresh process.
  Future<String?> refreshAccessToken() async {
    try {
      debugPrint('refreshAccessToken: Attempting to refresh token.');
      GoogleSignInAccount? account = _googleSignIn.currentUser; // Use a local variable
      if (account == null) {
        debugPrint('refreshAccessToken: No user is currently signed in. Attempting silent sign-in.');
        account = await _googleSignIn.signInSilently(); // Try to sign in silently
        if (account == null) {
          debugPrint('refreshAccessToken: Silent sign-in failed. Cannot refresh token.');
          return null;
        }
      }

      final auth = await account.authentication; // Use the local 'account' variable
      debugPrint('refreshAccessToken: Current access token: ${auth.accessToken}');
      // The authenticatedClient() extension method handles refreshing if needed
      // We just need to ensure _googleSignIn.currentUser is not null
      final refreshedAuth = await account.authentication; // Use the local 'account' variable
      debugPrint('refreshAccessToken: Refreshed access token: ${refreshedAuth.accessToken}');
      return refreshedAuth.accessToken;
    } catch (error) {
      debugPrint('refreshAccessToken: Error refreshing access token: $error');
      return null;
    }
  }
}
