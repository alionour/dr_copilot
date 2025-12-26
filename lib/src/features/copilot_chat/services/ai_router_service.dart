import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
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
class AIRouterService {
  final GeminiService _geminiService;
  final GPTService _gptService;
  final ClaudeService _claudeService;
  final DeepSeekService _deepSeekService;
  final SubscriptionService _subscriptionService;

  AIRouterService({
    required GeminiService geminiService,
    required GPTService gptService,
    required ClaudeService claudeService,
    required DeepSeekService deepSeekService,
    required SubscriptionService subscriptionService,
  })  : _geminiService = geminiService,
        _gptService = gptService,
        _claudeService = claudeService,
        _deepSeekService = deepSeekService,
        _subscriptionService = subscriptionService;

  /// Classifies query complexity using Gemini Flash
  Future<QueryComplexity> classifyQueryComplexity(String query) async {
    try {
      final classifierPrompt =
          '''Classify this medical query complexity in ONE word only.

Query: "$query"

Reply with ONLY one word: SIMPLE, MODERATE, or COMPLEX

Classification Rules:
- SIMPLE: Basic questions, data lookups, simple summaries, greetings, scheduling requests
- MODERATE: Medical reasoning with structured data, treatment plans for common conditions
- COMPLEX: Differential diagnosis, multi-step clinical reasoning, drug interactions, safety-critical decisions

Your response (one word only):''';

      final response = await _geminiService.generateResponse(
        classifierPrompt,
        messageHistory: [],
      );

      final classification = response.trim().toUpperCase();

      debugPrint(
          '[AIRouter] Query: "${query.substring(0, query.length > 50 ? 50 : query.length)}..." -> $classification');

      if (classification.contains('SIMPLE')) {
        return QueryComplexity.simple;
      } else if (classification.contains('MODERATE')) {
        return QueryComplexity.moderate;
      } else if (classification.contains('COMPLEX')) {
        return QueryComplexity.complex;
      }

      // Default to moderate if unclear
      debugPrint('[AIRouter] Unclear classification, defaulting to MODERATE');
      return QueryComplexity.moderate;
    } catch (e) {
      debugPrint('[AIRouter] Classification error: $e, defaulting to MODERATE');
      return QueryComplexity.moderate;
    }
  }

  /// Gets the appropriate AI service based on query complexity and user tier
  Future<AIService> getServiceForQuery({
    required String query,
    required String? clinicId,
    bool forcePremium = false,
  }) async {
    // Fetch user's subscription tier
    final userTier = clinicId != null
        ? await _subscriptionService.getCurrentTier(clinicId)
        : SubscriptionTier.free;

    // If user forces premium, use best available model
    if (forcePremium) {
      debugPrint(
          '[AIRouter] Premium mode forced, using ${_getBestServiceForTier(userTier)}');
      return _getBestServiceForTier(userTier);
    }

    // Classify query complexity
    final complexity = await classifyQueryComplexity(query);

    // Route based on complexity and tier
    switch (complexity) {
      case QueryComplexity.simple:
        // Always use Gemini Flash for simple queries (free/cheap)
        debugPrint('[AIRouter] SIMPLE -> Gemini Flash');
        return _geminiService;

      case QueryComplexity.moderate:
        // Use DeepSeek for moderate (cost-effective reasoning)
        // Fall back to Gemini if user doesn't have DeepSeek access
        if (userTier.canUseAdvancedModels) {
          debugPrint('[AIRouter] MODERATE -> DeepSeek');
          return _deepSeekService;
        } else {
          debugPrint('[AIRouter] MODERATE -> Gemini Flash (tier limited)');
          return _geminiService;
        }

      case QueryComplexity.complex:
        // Use premium models for complex queries
        debugPrint('[AIRouter] COMPLEX -> ${_getBestServiceForTier(userTier)}');
        return _getBestServiceForTier(userTier);
    }
  }

  /// Returns the best service available for the user's subscription tier
  AIService _getBestServiceForTier(SubscriptionTier tier) {
    if (tier.canUseEliteModels) {
      // Elite tier: Use Claude (best reasoning)
      return _claudeService;
    } else if (tier.canUseAdvancedModels) {
      // Pro tier: Use GPT-4o
      return _gptService;
    } else {
      // Free tier: Use Gemini Flash
      return _geminiService;
    }
  }
}
