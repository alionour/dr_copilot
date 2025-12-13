import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
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

    // Success/Cancel URLs
    // In a real desktop app, you might use a deep link scheme like 'drcopilot://payment/success'
    // For now, we'll redirect to a generic success page or a placeholder.
    const successUrl = 'https://google.com?status=success'; // Placeholder
    const cancelUrl = 'https://google.com?status=cancel'; // Placeholder

    final body = json.encode({
      'clinicId': clinicId,
      'planId': planId,
      'period': period,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });

    log('--- Creating Paddle Checkout Session ---');
    log('URL: $url');
    log('Body: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      log('Response Status: ${response.statusCode}');
      log('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'] as String?;
      } else {
        log('Failed to create session: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Exception creating session: $e');
      return null;
    }
  }
}
