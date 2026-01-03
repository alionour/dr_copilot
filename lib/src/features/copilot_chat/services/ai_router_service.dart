import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/groq_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:flutter/foundation.dart';

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
  final GPTService _gptService;
  final ClaudeService _claudeService;
  final DeepSeekService _deepSeekService;
  final GroqService _groqService;
  final SubscriptionService _subscriptionService;

  AIRouterService({
    required GeminiService geminiService,
    required GPTService gptService,
    required ClaudeService claudeService,
    required DeepSeekService deepSeekService,
    required GroqService groqService,
    required SubscriptionService subscriptionService,
  })  : _geminiService = geminiService,
        _gptService = gptService,
        _claudeService = claudeService,
        _deepSeekService = deepSeekService,
        _groqService = groqService,
        _subscriptionService = subscriptionService;

  /// Gets the appropriate AI service based on query complexity and user tier
  /// Groq is used by default (free, fast, supports function calling)
  /// Gemini can be used for premium users
  Future<AIService> getServiceForQuery({
    required String query,
    required String? clinicId,
    bool forcePremium = false,
  }) async {
    // Fetch user's subscription tier
    final userTier = clinicId != null
        ? await _subscriptionService.getCurrentTier(clinicId)
        : SubscriptionTier.free;

    // If user forces premium, use Gemini (best function calling support)
    if (forcePremium) {
      debugPrint('[AIRouter] Premium mode forced, using Gemini');
      return _geminiService;
    }

    // Use Groq by default (free tier, has function calling support)
    debugPrint('[AIRouter] Using Groq (free, supports function calling)');
    return _groqService;
  }

  /// Returns the best service available for the user's subscription tier
  AIService _getBestServiceForTier(SubscriptionTier tier) {
    if (tier.canUseEliteModels) {
      return _claudeService;
    } else if (tier.canUseAdvancedModels) {
      return _gptService;
    } else {
      return _groqService;
    }
  }
}
