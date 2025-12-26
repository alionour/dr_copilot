import 'dart:typed_data';

abstract class AIService {
  Future<String> generateResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  });

  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  });

  /// Updates the model configuration with user-defined preferences, e.g., required fields.
  void updateModelConfig(List<String> requiredFields);
}
