import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class VertexAIService {
  final String apiKey;

  VertexAIService(this.apiKey);

  Future<String> getMedPaLMResponse(String query) async {
    final url = Uri.parse(
        'https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/models/YOUR_MODEL_ID:predict');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'instances': [
          {'content': query}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['predictions'][0]['content'];
    } else {
      throw Exception('Failed to get response from Vertex AI');
    }
  }

  Future<String> getMedPaLMResponseFromBytes(Uint8List fileBytes) async {
    final url = Uri.parse(
        'https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/models/YOUR_MODEL_ID:predict');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'instances': [
          {'content': base64Encode(fileBytes)}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['predictions'][0]['content'];
    } else {
      throw Exception('Failed to get response from Vertex AI');
    }
  }
}
