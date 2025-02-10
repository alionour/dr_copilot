import 'dart:typed_data';

import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiResponse {
  final List<Part> parts;

  GeminiResponse(this.parts);
}

class GeminiService {
  final String apiKey;
  late final Gemini _gemini;

  GeminiService(this.apiKey) {
    _gemini = Gemini.init(apiKey: apiKey);
  }

  Future<GeminiResponse> getGeminiResponse(String query) async {
    try {
      final response = await _gemini.prompt(
        parts: [Part.text(query)],
      );
      if (response == null ||
          response.content == null ||
          response.content!.parts == null ||
          response.content!.parts!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return GeminiResponse(response.content!.parts!);
    } catch (e) {
      throw Exception('Failed to get response from Gemini: $e');
    }
  }

  Future<GeminiResponse> getGeminiResponseFromBytes(
      Uint8List fileBytes, String text) async {
    try {
      final response = await _gemini.prompt(
        parts: [
          Part.text(text),
          Part.bytes(fileBytes),
        ],
      );
      if (response == null ||
          response.content == null ||
          response.content!.parts == null ||
          response.content!.parts!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      return GeminiResponse(response.content!.parts!);
    } catch (e) {
      throw Exception('Failed to get response from Gemini: $e');
    }
  }
}
