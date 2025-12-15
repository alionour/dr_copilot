import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service to manage OAuth tokens for bot account Google Drive access
///
/// This service handles:
/// - Loading refresh token from environment (Doppler)
/// - Automatically refreshing access tokens when expired
/// - Providing valid access tokens for API calls
class GoogleOAuthTokenService {
  String? _accessToken;
  DateTime? _tokenExpiry;

  final String _clientId;
  final String _clientSecret;
  final String _refreshToken;

  GoogleOAuthTokenService({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
  }) : _clientId = clientId,
       _clientSecret = clientSecret,
       _refreshToken = refreshToken;

  /// Get a valid access token (automatically refreshes if expired)
  Future<String> getAccessToken() async {
    // Return cached token if still valid
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(Duration(minutes: 5)))) {
      debugPrint('[GoogleOAuthTokenService] Using cached access token');
      return _accessToken!;
    }

    // Token expired or not present, refresh it
    debugPrint('[GoogleOAuthTokenService] Access token expired, refreshing...');
    await _refreshAccessToken();

    return _accessToken!;
  }

  /// Refresh the access token using the stored refresh token
  Future<void> _refreshAccessToken() async {
    try {
      debugPrint(
        '[GoogleOAuthTokenService] Exchanging refresh token for access token...',
      );

      // Exchange refresh token for new access token
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'refresh_token': _refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          '[GoogleOAuthTokenService] Token refresh failed: ${response.body}',
        );
        throw Exception(
          'Failed to refresh access token: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];

      // Set expiry (usually 3600 seconds = 1 hour)
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      debugPrint(
        '[GoogleOAuthTokenService] Access token refreshed successfully',
      );
      debugPrint('[GoogleOAuthTokenService] Token expires at: $_tokenExpiry');
    } catch (e, stackTrace) {
      debugPrint('[GoogleOAuthTokenService] ERROR refreshing token: $e');
      debugPrint('[GoogleOAuthTokenService] Stack trace: $stackTrace');
      rethrow;
    }
  }
}

