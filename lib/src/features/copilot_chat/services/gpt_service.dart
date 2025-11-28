import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:http/http.dart' as http;

class GPTService implements AIService {
  final String apiKey;

  GPTService(this.apiKey);

  @override
  Future<String> generateResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    return getGPTResponse(query, messageHistory: messageHistory);
  }

  @override
  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    // Using GPT-4o for vision capabilities
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = <Map<String, dynamic>>[];

    // Add history if needed, but usually vision requests are standalone or last in chain
    // For simplicity, we'll just send the current query and image

    messages.add({
      'role': 'user',
      'content': [
        {'type': 'text', 'text': query},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}'
          }
        }
      ]
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': messages,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get response from GPT: ${errorData['error']['message']}');
    }
  }

  Future<String> getGPTResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Build messages array with history
    final List<Map<String, dynamic>> messages = [];

    // Add system message
    messages.add({
      'role': 'system',
      'content':
          'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals.',
    });

    // Add message history
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      if (text.isNotEmpty) {
        messages.add({
          'role': isUser ? 'user' : 'assistant',
          'content': text,
        });
      }
    }

    // Add current query
    messages.add({
      'role': 'user',
      'content': query,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': messages,
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get response from GPT: ${errorData['error']['message']}');
    }
  }
}
