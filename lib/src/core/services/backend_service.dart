import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

/// Service for communicating with the backend API (AWS Lambda).
class BackendService {
  static const String baseUrl =
      'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com';

  /// Checks the health of the backend service.
  ///
  /// Returns `true` if the backend is reachable and initialized.
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('Backend status: ${data['message']}');
        return data['firebaseInitialized'] == true;
      }
      return false;
    } catch (e) {
      log('Health check failed: $e');
      return false;
    }
  }

  /// Sends an invitation email to a user.
  ///
  /// Returns a map with `success` and `message` or `error`.
  static Future<Map<String, dynamic>> sendInvitation({
    required String recipientEmail,
    required String recipientName,
    required String clinicName,
    required String clinicId,
    required String role,
  }) async {
    final url = Uri.parse('$baseUrl/invitations');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'recipientEmail': recipientEmail,
      'recipientName': recipientName,
      'clinicName': clinicName,
      'clinicId': clinicId,
      'role': role,
    });

    log('--- Sending Invitation ---');
    log('URL: $url');
    log('Headers: $headers');
    log('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      log('--- Invitation Response ---');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        log('Invitation sent successfully via backend.');
        return {
          'success': true,
          'messageId': data['messageId'],
          'message': data['message'],
        };
      } else {
        log('Backend returned an error for invitation.');
        return {
          'success': false,
          'error': data['error'] ?? data['message'] ?? 'Unknown backend error',
        };
      }
    } catch (e) {
      log('--- Invitation Exception ---');
      log('Exception caught while sending invitation: $e');
      return {
        'success': false,
        'error': 'Failed to communicate with backend: $e',
      };
    }
  }

  /// Sends a push notification to a user.
  static Future<Map<String, dynamic>> sendNotification({
    required String userId,
    required String title,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'title': title,
          'message': message,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'messageId': data['messageId'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send notification: $e',
      };
    }
  }

  /// Verifies if an invitation token is valid.
  static Future<Map<String, dynamic>> verifyInvitation(String token) async {
    log('--- Verifying Invitation ---');
    log('Token: $token');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/invitations/verify?token=$token'),
      );

      log('--- Verify Invitation Response ---');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      log('--- Verify Invitation Exception ---');
      log('Exception caught while verifying invitation: $e');
      return {'valid': false, 'error': 'Network error'};
    }
  }

  /// Accepts an invitation for a user using the given token.
  static Future<Map<String, dynamic>> acceptInvitation({
    required String token,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/invitations/accept');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'token': token,
      'userId': userId,
    });

    log('--- Accepting Invitation ---');
    log('URL: $url');
    log('Headers: $headers');
    log('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      log('--- Accept Invitation Response ---');
      log('Status Code: ${response.statusCode}');
      log('Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        log('Invitation accepted successfully via backend.');
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        log('Backend returned an error for accepting invitation.');
        return {
          'success': false,
          'error': data['error'] ?? data['message'] ?? 'Unknown backend error',
        };
      }
    } catch (e) {
      log('--- Accept Invitation Exception ---');
      log('Exception caught while accepting invitation: $e');
      return {
        'success': false,
        'error': 'Failed to communicate with backend: $e',
      };
    }
  }
}
