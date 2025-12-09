import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/services/backend_service.dart';

class PaddleService {
  // Use the same base URL as the rest of the app, or a local override
  // For local testing, you might need to change this to 'http://localhost:3000'
  static String get _baseUrl => BackendService.baseUrl;

  static Future<String?> createCheckoutSession({
    required String planId,
    required String clinicId,
    String period = 'monthly',
  }) async {
    final url = Uri.parse('$_baseUrl/payment/create-checkout-session');

    // Success/Cancel URLs using deep link scheme
    final successUrl = 'drcopilot://payment/success?plan=$planId';
    final cancelUrl = 'drcopilot://payment/cancel';

    // Get the current user's ID token
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    // Force refresh to ensure we have a valid token
    final token = await user.getIdToken(true);

    print('Token retrieved: ${token?.substring(0, 10)}...');
    if (token == null) {
      throw Exception('Failed to retrieve ID token');
    }

    // Attempting to pass token in body as well
    final body = json.encode({
      'clinicId': clinicId,
      'planId': planId,
      'period': period,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
      'idToken': token,
    });

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    print('--- Creating Paddle Checkout Session ---');
    print('URL: $url');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);

      print('Actual Request Headers: ${response.request?.headers}');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'] as String?;
      } else {
        print('Failed to create session: ${response.body}');
        throw Exception(
          'Failed to create session: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Exception creating session: $e');
      throw Exception('Error creating session: $e');
    }
  }
}
