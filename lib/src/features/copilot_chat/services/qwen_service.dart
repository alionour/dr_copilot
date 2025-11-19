import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class QwenService {
  final String apiKey;

  QwenService(this.apiKey);

  Future<String> getQwenResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final url = Uri.parse('https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation');
    
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
        'model': 'qwen-turbo',
        'input': {
          'messages': messages,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['output']['text'];
    } else {
      throw Exception('Failed to get response from Qwen: ${response.body}');
    }
  }

  Future<String> getQwenResponseFromBytes(Uint8List fileBytes) async {
    final url = Uri.parse('https://api.qwen.com/v1/query');
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
      throw Exception('Failed to get response from Qwen');
    }
  }
}
