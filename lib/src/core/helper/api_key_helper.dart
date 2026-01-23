import 'platform_env_io.dart' if (dart.library.html) 'platform_env_web.dart';

/// A helper class for managing and retrieving API keys used throughout the application.
///
/// This class provides utility methods and properties to securely access and handle
/// API keys required for external service integrations.
///
/// On web, uses compile-time environment variables (String.fromEnvironment).
/// On desktop/mobile, uses runtime environment variables (Platform.environment).
class ApiKeyHelper {
  /// Retrieves the Vertex AI API key.
  static String get vertexAIKey {
    const key = String.fromEnvironment('VERTEX_AI_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('VERTEX_AI_KEY');
  }

  /// Retrieves the GPT API key.
  static String get gptKey {
    const key = String.fromEnvironment('GPT_API_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('GPT_API_KEY');
  }

  /// Retrieves the Gemini API key.
  static String get geminiKey {
    const key = String.fromEnvironment('GEMINI_API_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('GEMINI_API_KEY');
  }

  /// Retrieves the DeepSeek API key.
  static String get deepSeekKey {
    const key = String.fromEnvironment('DEEPSEEK_API_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('DEEPSEEK_API_KEY');
  }

  /// Retrieves the Qwen API key.
  static String get qwenKey {
    const key = String.fromEnvironment('QWEN_API_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('QWEN_API_KEY');
  }

  /// Retrieves the Claude API key.
  static String get claudeKey {
    const key = String.fromEnvironment('CLAUDE_API_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('CLAUDE_API_KEY');
  }

  /// Retrieves the Deepgram API key.
  static String get deepgramKey {
    const key = String.fromEnvironment('DEEPGRAM_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('DEEPGRAM_KEY');
  }

  /// Retrieves the Groq API key.
  static String get groqKey {
    const key = String.fromEnvironment('GROQ_API_KEY');
    return key.isNotEmpty ? key : getPlatformEnv('GROQ_API_KEY');
  }
}
