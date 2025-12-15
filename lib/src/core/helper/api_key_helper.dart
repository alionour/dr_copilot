import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_env_io.dart' if (dart.library.html) 'platform_env_web.dart';

/// A helper class for managing and retrieving API keys used throughout the application.
///
/// This class provides utility methods and properties to securely access and handle
/// API keys required for external service integrations.
///
/// On web, uses compile-time environment variables (String.fromEnvironment).
/// On desktop/mobile, uses runtime environment variables (Platform.environment).
class ApiKeyHelper {
  /// Retrieves the Vertex AI API key from the environment variables.
  static String get vertexAIKey => kIsWeb
      ? const String.fromEnvironment('VERTEX_AI_KEY', defaultValue: '')
      : getPlatformEnv('VERTEX_AI_KEY');

  /// Retrieves the GPT API key from the environment variables.
  static String get gptKey => kIsWeb
      ? const String.fromEnvironment('GPT_KEY', defaultValue: '')
      : getPlatformEnv('GPT_KEY');

  /// Retrieves the Gemini API key from the environment variables.
  static String get geminiKey => kIsWeb
      ? const String.fromEnvironment('GEMINI_KEY', defaultValue: '')
      : getPlatformEnv('GEMINI_KEY');

  /// Retrieves the DeepSeek API key from the environment variables.
  static String get deepSeekKey => kIsWeb
      ? const String.fromEnvironment('DEEP_SEEK_KEY', defaultValue: '')
      : getPlatformEnv('DEEP_SEEK_KEY');

  /// Retrieves the Qwen API key from the environment variables.
  static String get qwenKey => kIsWeb
      ? const String.fromEnvironment('QWEN_KEY', defaultValue: '')
      : getPlatformEnv('QWEN_KEY');

  /// Retrieves the Claude API key from the environment variables.
  static String get claudeKey => kIsWeb
      ? const String.fromEnvironment('CLAUDE_KEY', defaultValue: '')
      : getPlatformEnv('CLAUDE_KEY');

  /// Retrieves the Deepgram API key from the environment variables.
  static String get deepgramKey => kIsWeb
      ? const String.fromEnvironment('DEEPGRAM_KEY', defaultValue: '')
      : getPlatformEnv('DEEPGRAM_KEY');
}

