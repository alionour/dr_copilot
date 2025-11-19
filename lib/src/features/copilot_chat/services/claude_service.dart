import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ClaudeService {
  final String apiKey;

  ClaudeService(this.apiKey);

  Future<String> getClaudeResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');
    
    // Build messages array with history
    final List<Map<String, dynamic>> messages = [];
    
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
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 1024,
        'system': 'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals.',
        'messages': messages,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    } else {
      throw Exception('Failed to get response from Claude: ${response.body}');
    }
  }

  Future<String> getClaudeResponseFromBytes(Uint8List fileBytes) async {
    final url = Uri.parse('https://api.claude.com/v1/query');
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
      throw Exception('Failed to get response from Claude');
    }
  }
}
