import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class GPTService {
  final String apiKey;

  GPTService(this.apiKey);

  Future<String> getGPTResponse(String query) async {
    final url = Uri.parse(
        'https://api.openai.com/v1/engines/gpt-3.5-turbo/completions');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'prompt': query,
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
