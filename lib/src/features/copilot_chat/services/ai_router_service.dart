import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';

import 'package:dr_copilot/src/features/copilot_chat/services/groq_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';

/// Defines the complexity level of a user query
enum QueryComplexity {
  simple, // Basic questions, data lookups, simple summaries
  moderate, // Requires reasoning but straightforward
  complex, // Multi-step diagnosis, safety-critical, drug interactions
}

/// Routes queries to cost-appropriate AI models based on complexity
/// Supports function calling via Groq (free) or Gemini (premium)
class AIRouterService {
  final GeminiService _geminiService;
  final GroqService _groqService;

  AIRouterService({
    required GeminiService geminiService,
    required GroqService groqService,
    required SubscriptionService subscriptionService,
  })  : _geminiService = geminiService,
        _groqService = groqService;

  /// Gets the appropriate AI service based on query complexity and user tier
  /// Groq is used by default (free, fast, supports function calling)
  /// Gemini can be used for premium users
  Future<AIService> getServiceForQuery({
    required String query,
    required String? clinicId,
    bool forcePremium = false,
  }) async {
    // If user forces premium, use Gemini (best function calling support)
    if (forcePremium) {
      return _geminiService;
    }

    // Use Groq by default (free tier, has function calling support)
    return _groqService;
  }
}
