/// A helper class for retrieving various API keys from environment variables.
///
/// This class provides static getters to access API keys for different services,
/// such as Vertex AI, GPT, Gemini, DeepSeek, Qwen, and Claude. The keys are
/// fetched from the corresponding environment variables. If an environment
/// variable is not set, an empty string is returned.
///
/// Example usage:
/// ```dart
/// final gptApiKey = ApiKeyHelper.gptKey;
/// ```
import 'dart:io';

/// A helper class for managing and retrieving API keys used throughout the application.
/// 
/// This class provides utility methods and properties to securely access and handle
/// API keys required for external service integrations.
class ApiKeyHelper {
  /// Retrieves the Vertex AI API key from the environment variables.
  /// 
  /// Returns the value of the 'VERTEX_AI_KEY' environment variable if it exists,
  /// otherwise returns an empty string.
  /// 
  /// This is useful for securely accessing the Vertex AI API key without hardcoding
  /// it in the source code.
  static String get vertexAIKey => Platform.environment['VERTEX_AI_KEY'] ?? '';
  /// Retrieves the GPT API key from the environment variables.
  ///
  /// Returns the value of the 'GPT_KEY' environment variable if it exists,
  /// otherwise returns an empty string.
  ///
  /// This is useful for securely accessing API keys without hardcoding them
  /// into the source code.
  static String get gptKey => Platform.environment['GPT_KEY'] ?? '';
  /// Retrieves the Gemini API key from the environment variables.
  ///
  /// Returns the value of the 'GEMINI_KEY' environment variable if it exists,
  /// otherwise returns an empty string.
  static String get geminiKey => Platform.environment['GEMINI_KEY'] ?? '';
  /// Retrieves the DeepSeek API key from the environment variables.
  ///
  /// Returns the value of the 'DEEP_SEEK_KEY' environment variable if it exists,
  /// otherwise returns an empty string.
  ///
  /// Useful for securely accessing the DeepSeek API key without hardcoding it
  /// in the source code.
  static String get deepSeekKey => Platform.environment['DEEP_SEEK_KEY'] ?? '';
  /// Retrieves the Qwen API key from the environment variables.
  ///
  /// Returns the value of the 'QWEN_KEY' environment variable if it exists,
  /// otherwise returns an empty string.
  static String get qwenKey => Platform.environment['QWEN_KEY'] ?? '';
  /// Retrieves the Claude API key from the environment variables.
  ///
  /// Returns the value of the 'CLAUDE_KEY' environment variable if it exists,
  /// otherwise returns an empty string.
  static String get claudeKey => Platform.environment['CLAUDE_KEY'] ?? '';
}
