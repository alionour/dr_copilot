import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:http/http.dart' as http;

class VertexAIService implements AIService {
  final String apiKey;

  VertexAIService(this.apiKey);

  @override
  Future<String> generateResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    return getMedPaLMResponse(query, messageHistory: messageHistory);
  }

  @override
  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    // Vertex AI (MedPaLM) might handle images differently, but for now we map to the existing byte method
    // Note: The existing method didn't take a query with the image, just the image.
    // We might need to adjust this if the API supports both.
    // For now, let's assume we just send the image as per previous implementation,
    // or we can try to send both if the API allows.
    // Looking at the previous implementation `getMedPaLMResponseFromBytes`, it only sent bytes.
    return getMedPaLMResponseFromBytes(imageBytes);
  }

  Future<String> getMedPaLMResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final url = Uri.parse(
        'https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/models/YOUR_MODEL_ID:predict');

    // Build context from message history
    String context = '';
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      if (text.isNotEmpty) {
        context += '${isUser ? "User" : "Assistant"}: $text\n';
      }
    }

    // Combine context with current query
    final fullPrompt =
        context.isNotEmpty ? '$context\nUser: $query\nAssistant:' : query;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'instances': [
          {'content': fullPrompt}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['predictions'][0]['content'];
    } else {
      throw Exception(
          'Failed to get response from Vertex AI: ${response.body}');
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
