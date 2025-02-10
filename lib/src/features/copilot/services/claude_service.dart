import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ClaudeService {
  final String apiKey;

  ClaudeService(this.apiKey);

  Future<String> getClaudeResponse(String query) async {
    final url = Uri.parse('https://api.claude.com/v1/query');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'query': query,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      throw Exception('Failed to get response from Claude');
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
