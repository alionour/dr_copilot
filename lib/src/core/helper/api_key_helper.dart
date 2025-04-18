import 'dart:io';

class ApiKeyHelper {
  static String get vertexAIKey => Platform.environment['VERTEX_AI_KEY'] ?? '';
  static String get gptKey => Platform.environment['GPT_KEY'] ?? '';
  static String get geminiKey => Platform.environment['GEMINI_KEY'] ?? '';
  static String get deepSeekKey => Platform.environment['DEEP_SEEK_KEY'] ?? '';
  static String get qwenKey => Platform.environment['QWEN_KEY'] ?? '';
  static String get claudeKey => Platform.environment['CLAUDE_KEY'] ?? '';
}
