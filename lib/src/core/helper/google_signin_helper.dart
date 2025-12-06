import 'dart:convert';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/docs/v1.dart' as docs;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:universal_io/io.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

/// A list of OAuth 2.0 scopes required for Google Sign-In, Calendar, Drive, and Docs API access.
final scopes = [
  'profile',
  'email',
  'openid',
  CalendarApi.calendarScope,
  CalendarApi.calendarEventsScope,
  CalendarApi.calendarReadonlyScope,
  CalendarApi.calendarEventsReadonlyScope,
  CalendarApi.calendarSettingsReadonlyScope,
  drive.DriveApi.driveScope,
  docs.DocsApi.documentsScope,
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
        'Request type not supported for retry: \\${request.runtimeType}',
      );
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
      debugPrint('User signed in: $account');
    });
  }

  static const _webClientId = String.fromEnvironment('WEB_CLIENT_ID');

  /// Getter for the standard Google Sign-In instance.
  GoogleSignIn get _googleSignIn {
    return GoogleSignIn(clientId: kIsWeb ? _webClientId : null, scopes: scopes);
  }

  Client? _client;

  /// Ensures the authenticated client is initialized and returns it.
  Future<Client?> ensureClientInitialized() async {
    try {
      if (_client == null) {
        // Try to sign in silently first
        GoogleSignInAccount? currentUser = await _googleSignIn.signInSilently();
        debugPrint(
          'Called signInSilently for GoogleSignIn. Current user: $currentUser',
        );

        if (currentUser != null) {
          _client = await _googleSignIn.authenticatedClient();
          debugPrint('Initialized _client from silent sign-in: $_client');
        } else if (io.Platform.isWindows || io.Platform.isLinux) {
          // Desktop specific silent sign-in check could go here if we stored tokens
          // For now, we rely on the caller to initiate interactive sign-in if needed
          debugPrint('Desktop: Silent sign-in not fully implemented yet.');
        } else {
          // For other platforms (Android, iOS, Web)
          currentUser = await _googleSignIn.signIn();
          debugPrint(
            'Called interactive signIn for GoogleSignIn. Current user: $currentUser',
          );

          if (currentUser != null) {
            _client = await _googleSignIn.authenticatedClient();
            debugPrint(
              'Initialized _client from interactive sign-in: $_client',
            );
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Error initializing _client: $e\n$stack');
      _client = null;
    }
    return _client;
  }

  Future<Client?> get client async {
    if (_client == null) {
      await ensureClientInitialized();
    }
    debugPrint('Accessing client: $_client');
    return _client;
  }

  Future<void> signOut() async {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      // Clear stored tokens for desktop
      await secureStorage.delete(key: 'desktop_auth_access_token');
      await secureStorage.delete(key: 'desktop_auth_refresh_token');
      _client = null;
    } else {
      await _googleSignIn.signOut();
    }
    debugPrint('User signed out');
  }

  Stream<GoogleSignInAccount?> get onAuthStateChanged =>
      _googleSignIn.onCurrentUserChanged;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      debugPrint('User signed in: $account');
      return account;
    } catch (error) {
      debugPrint('Sign in error: $error');
      return null;
    }
  }

  /// Signs in the user using a custom loopback flow for Desktop.
  Future<DesktopAuthResult?> signInAllPlatforms() async {
    if (!io.Platform.isWindows && !io.Platform.isLinux) {
      throw UnsupportedError('This method is for desktop only.');
    }

    try {
      final clientId = io.Platform.environment['WEB_CLIENT_ID'];
      final clientSecret = io.Platform.environment['WEB_CLIENT_SECRET'];
      final redirectPortStr = io.Platform.environment['WEB_REDIRECT_PORT'];

      if (clientId == null || clientSecret == null || redirectPortStr == null) {
        debugPrint(
          'Error: WEB_CLIENT_ID, WEB_CLIENT_SECRET, or WEB_REDIRECT_PORT not found in environment.',
        );
        return null;
      }

      final redirectPort = int.parse(redirectPortStr);

      // 1. Create a local server
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        redirectPort,
      );
      final redirectUri = 'http://localhost:${server.port}';
      debugPrint('Listening on $redirectUri');

      // 2. Construct the OAuth URL
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': scopes.join(' '),
        'access_type': 'offline', // Important for refresh token
        'prompt':
            'consent', // Forces refresh_token to be returned even on re-auth
      });

      // 3. Launch the URL
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl);
      } else {
        debugPrint('Could not launch $authUrl');
        await server.close();
        return null;
      }

      // 4. Listen for the redirect
      String? authCode;
      await for (final request in server) {
        final code = request.uri.queryParameters['code'];
        if (code != null) {
          authCode = code;

          // 5. Serve the custom success page
          try {
            final htmlContent = await rootBundle.loadString(
              'assets/html/success_login.html',
            );
            request.response
              ..statusCode = io.HttpStatus.ok
              ..headers.contentType = io.ContentType.html
              ..write(htmlContent);
          } catch (e) {
            debugPrint('Error loading success page: $e');
            request.response
              ..statusCode = io.HttpStatus.ok
              ..headers.contentType = io.ContentType.html
              ..write(
                '<html><body><h1>Login Successful</h1><p>You can close this window.</p></body></html>',
              );
          }

          await request.response.close();
          break; // Stop listening after receiving the code
        } else {
          request.response
            ..statusCode = io.HttpStatus.badRequest
            ..write('Missing authorization code');
          await request.response.close();
        }
      }
      await server.close();

      if (authCode == null) return null;

      // 6. Exchange code for tokens
      final tokenResponse = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': authCode,
          'grant_type': 'authorization_code',
          'redirect_uri': redirectUri,
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        final accessToken = tokenData['access_token'];
        final idToken = tokenData['id_token'];
        final refreshToken = tokenData['refresh_token'];

        // Store tokens securely
        if (accessToken != null) {
          await secureStorage.write(
            key: 'desktop_auth_access_token',
            value: accessToken,
          );
        }
        if (idToken != null) {
          await secureStorage.write(
            key: 'desktop_auth_id_token',
            value: idToken,
          );
        }
        if (refreshToken != null) {
          await secureStorage.write(
            key: 'desktop_auth_refresh_token',
            value: refreshToken,
          );
        }

        // Create a client
        _client = AuthClient(
          accessToken,
          refreshTokenCallback: () async {
            debugPrint('[Desktop] Token expired, refreshing...');
            final newToken = await refreshAccessToken();
            if (newToken != null) {
              debugPrint('[Desktop] Token refreshed successfully');
            } else {
              debugPrint('[Desktop] Token refresh failed');
            }
            return newToken;
          },
        );

        return DesktopAuthResult(accessToken: accessToken, idToken: idToken);
      } else {
        debugPrint('Failed to exchange token: ${tokenResponse.body}');
        return null;
      }
    } catch (error) {
      debugPrint('Desktop sign in error: $error');
      return null;
    }
  }

  Future<String?> get idToken async {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      return await secureStorage.read(key: 'desktop_auth_id_token');
    }
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.idToken;
  }

  Future<String?> get accessToken async {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      return await secureStorage.read(key: 'desktop_auth_access_token');
    }
    final account = _googleSignIn.currentUser;
    if (account == null) {
      return null;
    }
    final auth = await account.authentication;
    return auth.accessToken;
  }

  Future<String?> refreshAccessToken() async {
    if (io.Platform.isWindows || io.Platform.isLinux) {
      try {
        debugPrint('[Desktop] Attempting to refresh access token...');

        final refreshToken = await secureStorage.read(
          key: 'desktop_auth_refresh_token',
        );
        if (refreshToken == null) {
          debugPrint(
            '[Desktop] No refresh token found. User needs to sign in again.',
          );
          return null;
        }

        final clientId = io.Platform.environment['WEB_CLIENT_ID'];
        final clientSecret = io.Platform.environment['WEB_CLIENT_SECRET'];

        if (clientId == null || clientSecret == null) {
          debugPrint('[Desktop] OAuth credentials not found in environment.');
          return null;
        }

        final response = await http.post(
          Uri.https('oauth2.googleapis.com', '/token'),
          body: {
            'client_id': clientId,
            'client_secret': clientSecret,
            'refresh_token': refreshToken,
            'grant_type': 'refresh_token',
          },
        );

        if (response.statusCode == 200) {
          final tokenData = jsonDecode(response.body);
          final newAccessToken = tokenData['access_token'];

          if (newAccessToken != null) {
            // Store the new access token
            await secureStorage.write(
              key: 'desktop_auth_access_token',
              value: newAccessToken,
            );

            // Update the client with the new token
            _client = AuthClient(
              newAccessToken,
              refreshTokenCallback: () async {
                debugPrint('[Desktop] Token expired, refreshing...');
                final token = await refreshAccessToken();
                if (token != null) {
                  debugPrint('[Desktop] Token refreshed successfully');
                } else {
                  debugPrint('[Desktop] Token refresh failed');
                }
                return token;
              },
            );

            debugPrint('[Desktop] Access token refreshed successfully');
            return newAccessToken;
          }
        } else {
          debugPrint(
            '[Desktop] Token refresh failed: ${response.statusCode} ${response.body}',
          );
          // If refresh token is invalid/expired, clear stored tokens
          await secureStorage.delete(key: 'desktop_auth_access_token');
          await secureStorage.delete(key: 'desktop_auth_refresh_token');
          await secureStorage.delete(key: 'desktop_auth_id_token');
        }
        return null;
      } catch (error) {
        debugPrint('[Desktop] Error refreshing access token: $error');
        return null;
      }
    }

    // Mobile/Web platforms
    try {
      debugPrint('refreshAccessToken: Attempting to refresh token.');
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      if (account == null) {
        debugPrint(
          'refreshAccessToken: No user is currently signed in. Attempting silent sign-in.',
        );
        account = await _googleSignIn.signInSilently();
        if (account == null) {
          debugPrint(
            'refreshAccessToken: Silent sign-in failed. Cannot refresh token.',
          );
          return null;
        }
      }
      final auth = await account.authentication;
      return auth.accessToken;
    } catch (error) {
      debugPrint('refreshAccessToken: Error refreshing access token: $error');
      return null;
    }
  }
}

class DesktopAuthResult {
  final String? accessToken;
  final String? idToken;

  DesktopAuthResult({this.accessToken, this.idToken});

  // Add compatibility getters if needed to match GoogleAuthentication
  String? get token => idToken;
}
