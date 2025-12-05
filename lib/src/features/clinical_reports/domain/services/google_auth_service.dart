import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class GoogleAuthService {
  static const _scopes = [
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/drive',
  ];

  AuthClient? _authenticatedClient;

  /// Get an authenticated client using the Service Account credentials
  Future<AuthClient> getAuthenticatedClient() async {
    if (_authenticatedClient != null) {
      return _authenticatedClient!;
    }

    try {
      // Load service account credentials from assets
      debugPrint(
        '[GoogleAuthService] Loading credentials from assets/google_credentials.json',
      );
      final jsonString = await rootBundle.loadString(
        'assets/google_credentials.json',
      );
      debugPrint('[GoogleAuthService] Credentials loaded, parsing JSON...');
      final credentials = ServiceAccountCredentials.fromJson(jsonString);
      debugPrint('[GoogleAuthService] Credentials parsed, authenticating...');

      // Create authenticated client
      _authenticatedClient = await clientViaServiceAccount(
        credentials,
        _scopes,
      );
      debugPrint('[GoogleAuthService] Authentication successful');
      return _authenticatedClient!;
    } catch (e, stackTrace) {
      debugPrint('[GoogleAuthService] ERROR: Failed to authenticate');
      debugPrint('[GoogleAuthService] Error details: $e');
      debugPrint('[GoogleAuthService] Stack trace: $stackTrace');
      throw Exception('Failed to authenticate with Google Service Account: $e');
    }
  }

  /// Close the client when done
  void dispose() {
    _authenticatedClient?.close();
    _authenticatedClient = null;
  }
}
