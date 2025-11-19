import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class GPTService {
  final String apiKey;

  GPTService(this.apiKey);

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
      'content': 'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals.',
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

  Future<String> getGPTResponseFromBytes(Uint8List fileBytes) async {
    final url = Uri.parse(
        'https://api.openai.com/v1/engines/gpt-3.5-turbo/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'prompt': base64Encode(fileBytes),
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['text'];
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get response from GPT: ${errorData['error']['message']}');
    }
  }
}
