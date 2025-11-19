import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class DeepSeekService {
  final String apiKey;

  DeepSeekService(this.apiKey);

  Future<String> getDeepSeekResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final url = Uri.parse('https://api.deepseek.com/chat/completions');
    
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
        'model': 'deepseek-chat',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get response from DeepSeek: ${response.body}');
    }
  }

  Future<String> getDeepSeekResponseFromBytes(Uint8List fileBytes) async {
    final url = Uri.parse('https://api.deepseek.com/v1/query');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'query': base64Encode(fileBytes),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception('Failed to get response from DeepSeek');
    }
  }
}
