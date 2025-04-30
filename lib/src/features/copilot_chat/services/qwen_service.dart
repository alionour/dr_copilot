import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class QwenService {
  final String apiKey;

  QwenService(this.apiKey);

  Future<String> getQwenResponse(String query) async {
    final url = Uri.parse('https://api.qwen.com/v1/query');
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
      throw Exception('Failed to get response from Qwen');
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
