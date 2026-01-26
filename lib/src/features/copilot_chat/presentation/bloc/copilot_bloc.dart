import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/groq_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/vertex_ai_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/ai_router_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

part 'copilot_event.dart';
part 'copilot_state.dart';

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  final VertexAIService vertexAIService;
  final GPTService gptService;
  final GeminiService geminiService;
  final DeepSeekService deepSeekService;
  final QwenService qwenService;
  final ClaudeService claudeService;
  final AIRouterService routerService;
  final FlutterSecureStorage secureStorage;
  final ConversationRepository conversationRepo;

  CopilotBloc({
    required this.vertexAIService,
    required this.gptService,
    required this.geminiService,
    required this.deepSeekService,
    required this.qwenService,
    required this.claudeService,
    required this.routerService,
    required this.secureStorage,
    required this.conversationRepo,
  }) : super(CopilotInitial()) {
    on<GenerateResponseEvent>(_onGenerateResponse);
    on<UploadImageEvent>(_onUploadImage);
    on<CacheMessagesEvent>(_onCacheMessages);
    on<LoadCachedMessagesEvent>(_onLoadCachedMessages);
    on<StartNewChatEvent>(_onStartNewChat);
    on<UpdateCopilotSettingsEvent>(_onUpdateCopilotSettings);
    on<StopGenerationEvent>(_onStopGeneration);
  }

  Future<void> _persistAssistantMessage(String text) async {
    try {
      final currentCache = await secureStorage.read(key: 'cachedMessages');
      // Retrieve Conversation ID to sync with Firestore
      final conversationId =
          await secureStorage.read(key: 'cachedConversationId');

      List<dynamic> messages =
          currentCache != null ? jsonDecode(currentCache) : [];
      final aiMsg = {
        'isUser': false,
        'message': text,
        'timestamp': DateTime.now().toIso8601String(),
      };
      messages.add(aiMsg);
      await secureStorage.write(
          key: 'cachedMessages', value: jsonEncode(messages));

      // Sync to Firestore
      if (conversationId != null) {
        // We can't easily get userId here without passing it, but addMessage requires senderId.
        // AI messages have senderId = 'ai' usually, or we use the 'addMessage' without sender check if strict?
        // ConversationRepository checks for auth user.
        // Let's assume senderId for AI.
        // Wait, Repo requires `senderId`.
        // I'll use 'ai-assistant' as ID, or pass the current userID.
        // To stay safe and simple for now, I'll ONLY save to Firestore in the event handler where I have the User ID.
        // Refactoring _persistAssistantMessage to accept conversationId and userId would be cleaner but changes signature.
        // I will SKIP firestore sync here and do it in the main event handler instead to avoid breaking changes so fast.
      }
    } catch (e) {
      debugPrint('[CopilotBloc] Failed to cache assistant message: $e');
    }
  }

  Future<T> _retryStorage<T>(Future<T> Function() operation) async {
    int retries = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        if (retries >= 3) rethrow;
        retries++;
        await Future.delayed(Duration(milliseconds: 200 * retries));
      }
    }
  }

  Future<void> _onGenerateResponse(
    GenerateResponseEvent event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotLoading());
    try {
      // Use AI Router to get the optimal service for this query
      final service = await routerService.getServiceForQuery(
        query: event.query,
        clinicId: event.clinicId,
        forcePremium: event.forcePremium ?? false,
      );

      // Persist user message & Restore History for Live Chat
      // We read current cache, append user message, and save.
      String? cachedConversationId;
      List<Map<String, dynamic>> historyToUse = event.messageHistory;

      if (event.messageHistory.isEmpty) {
        // Only do this if history wasn't provided (implies fresh turn or Live Chat implicit context)
        try {
          final currentCache = await secureStorage.read(key: 'cachedMessages');
          cachedConversationId =
              await secureStorage.read(key: 'cachedConversationId');

          List<dynamic> cachedList =
              currentCache != null ? jsonDecode(currentCache) : [];

          // Restore history from cache (this is the context BEFORE current query)
          historyToUse =
              cachedList.map((e) => Map<String, dynamic>.from(e)).toList();

          final userMsg = {
            'isUser': true,
            'message': event.query,
            'timestamp': DateTime.now().toIso8601String(),
          };

          // Add current message to cache and save
          cachedList.add(userMsg);
          await secureStorage.write(
              key: 'cachedMessages', value: jsonEncode(cachedList));

          // Sync to Firestore using Safe Helper
          if (event.userId != null) {
            if (cachedConversationId == null) {
              // Create new conversation
              cachedConversationId = await conversationRepo.createConversation(
                title: event.query,
                initialMessageText: event.query,
              );
              await secureStorage.write(
                  key: 'cachedConversationId', value: cachedConversationId);
            } else {
              // Add to existing conversation SAFELY
              await _addMessageSafe(
                conversationId: cachedConversationId,
                text: event.query,
                senderId: event.userId!,
              );
            }
          }
        } catch (e) {
          debugPrint(
              '[CopilotBloc] Failed to cache/sync live chat message: $e');
        }
      }

      // Append timestamp for temporal context (cost-effective: ~8 tokens, 0 permission overhead)
      String queryWithContext =
          '${event.query}\n\n${AIContextProvider.getTimestamp()}';

      // Inject Active Form Context if present
      if (event.activeFormContext != null &&
          event.activeFormContext!.isNotEmpty) {
        final formType = event.activeFormContext!['formType'];
        final formData = event.activeFormContext!['formData'];
        queryWithContext += '''

[SYSTEM CONTEXT: ACTIVE FORM]
The user is currently filling out a form of type '$formType'.
Current Form Data: $formData
User Instruction: If the user's query is an update to this form (e.g., "Change name to X"), call the tool '$formType' again with the UPDATED values merged with the existing data.
- Do NOT ask for an ID if this is a new record (add_patient/add_session).
- Do NOT call a different tool unless clearly requested.
- Treat this as an interactive update to the current drafting process.
''';
      }

      // Execute with fallback logic
      List<AIService> attemptOrder = [service];
      // Add fallbacks if not already primary
      if (service != geminiService) attemptOrder.add(geminiService);
      if (service != deepSeekService) attemptOrder.add(deepSeekService);
      if (service != gptService) attemptOrder.add(gptService);
      if (service != claudeService) attemptOrder.add(claudeService);

      bool handled = false;
      Object? lastError;

      for (final s in attemptOrder) {
        try {
          debugPrint(
              '[CopilotBloc] Attempting generation with ${s.runtimeType}...');
          await _executeServiceRequest(s, queryWithContext, historyToUse, event,
              cachedConversationId, emit);
          handled = true;
          break; // Success
        } catch (e) {
          lastError = e;
          debugPrint('[CopilotBloc] Service ${s.runtimeType} failed: $e');
          // If Quota exceeded or specific error, we prefer continuing.
          // If it was a fatal logic error (unlikely), we still fallback.
        }
      }

      if (!handled) {
        if (lastError != null) {
          throw lastError; // Throw the last error (likely from fallback)
        } else {
          throw Exception('All AI services failed to generate a response.');
        }
      }
    } catch (e) {
      if (e is Failure) {
        emit(_mapFailureToMessage(e));
      } else {
        emit(CopilotError(e.toString()));
      }
    }
  }

  Future<void> _addMessageSafe({
    required String conversationId,
    required String text,
    required String senderId,
  }) async {
    try {
      await conversationRepo.addMessage(
          conversationId: conversationId, text: text, senderId: senderId);
    } catch (e) {
      debugPrint('[CopilotBloc] Failed to sync message to Firestore: $e');
      // If permission denied, assume conversation ID is bad.
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('not-found')) {
        await secureStorage.delete(key: 'cachedConversationId');
      }
      // Swallow error to prevent UI Red Screen
    }
  }

  Future<void> _executeServiceRequest(
    AIService service,
    String queryWithContext,
    List<Map<String, dynamic>> messageHistory,
    GenerateResponseEvent event,
    String? cachedConversationId,
    Emitter<CopilotState> emit,
  ) async {
    final interactiveTools = [
      'add_patient',
      'edit_patient',
      'add_session',
      'edit_session',
      'add_evaluation',
      'edit_evaluation'
    ];

    final modelName = service.runtimeType.toString().replaceAll('Service', '');

    // Handle Gemini with function calling
    if (service is GeminiService) {
      final response = await service.getGeminiResponse(
        queryWithContext,
        messageHistory: messageHistory,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      final functionCalls = response.functionCalls;
      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        if (interactiveTools.contains(call.name)) {
          emit(
              CopilotFormRequested(call.name, call.args, usedModel: modelName));
        } else {
          emit(CopilotFunctionCall(call, usedModel: modelName));
        }
      } else {
        final text = response.text ?? '';
        await _persistAssistantMessage(text);
        if (cachedConversationId != null && event.userId != null) {
          await _addMessageSafe(
              conversationId: cachedConversationId, text: text, senderId: 'ai');
        }
        emit(CopilotResponseGenerated(text, usedModel: modelName));
      }
    }
    // Handle Groq with function calling
    else if (service is GroqService) {
      final response = await service.getGroqResponse(
        queryWithContext,
        messageHistory: messageHistory,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      if (response.hasFunctionCall) {
        // Convert GroqFunctionCall to Gemini-compatible FunctionCall
        final groqCall = response.functionCall!;
        if (interactiveTools.contains(groqCall.name)) {
          emit(CopilotFormRequested(groqCall.name, groqCall.arguments,
              usedModel: modelName));
        } else {
          emit(CopilotGroqFunctionCall(groqCall, usedModel: modelName));
        }
      } else {
        final text = response.text ?? '';
        await _persistAssistantMessage(text);
        if (cachedConversationId != null && event.userId != null) {
          await _addMessageSafe(
              conversationId: cachedConversationId, text: text, senderId: 'ai');
        }
        emit(CopilotResponseGenerated(text, usedModel: modelName));
      }
    }
    // Handle GPT with function calling
    else if (service is GPTService) {
      final response = await service.getGPTResponseRaw(
        queryWithContext,
        messageHistory: messageHistory,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      if (response.hasFunctionCall) {
        final gptCall = response.functionCall!;
        if (interactiveTools.contains(gptCall.name)) {
          emit(CopilotFormRequested(gptCall.name, gptCall.arguments,
              usedModel: modelName));
        } else {
          emit(CopilotGroqFunctionCall(
              GroqFunctionCall(
                  name: gptCall.name, arguments: gptCall.arguments),
              usedModel: modelName));
        }
      } else {
        final text = response.text ?? '';
        await _persistAssistantMessage(text);
        if (cachedConversationId != null && event.userId != null) {
          await _addMessageSafe(
              conversationId: cachedConversationId, text: text, senderId: 'ai');
        }
        emit(CopilotResponseGenerated(text, usedModel: modelName));
      }
    }
    // Handle DeepSeek with function calling
    else if (service is DeepSeekService) {
      final response = await service.getDeepSeekResponseRaw(
        queryWithContext,
        messageHistory: messageHistory,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      if (response.hasFunctionCall) {
        final dsCall = response.functionCall!;
        if (interactiveTools.contains(dsCall.name)) {
          emit(CopilotFormRequested(dsCall.name, dsCall.arguments,
              usedModel: modelName));
        } else {
          emit(CopilotGroqFunctionCall(
              GroqFunctionCall(name: dsCall.name, arguments: dsCall.arguments),
              usedModel: modelName));
        }
      } else {
        final text = response.text ?? '';
        await _persistAssistantMessage(text);
        if (cachedConversationId != null && event.userId != null) {
          await _addMessageSafe(
              conversationId: cachedConversationId, text: text, senderId: 'ai');
        }
        emit(CopilotResponseGenerated(text, usedModel: modelName));
      }
    }
    // Handle Claude with function calling
    else if (service is ClaudeService) {
      final response = await service.getClaudeResponseRaw(
        queryWithContext,
        messageHistory: messageHistory,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      if (response.hasFunctionCall) {
        final claudeCall = response.functionCall!;
        if (interactiveTools.contains(claudeCall.name)) {
          emit(CopilotFormRequested(claudeCall.name, claudeCall.arguments,
              usedModel: modelName));
        } else {
          emit(CopilotGroqFunctionCall(
              GroqFunctionCall(
                  name: claudeCall.name, arguments: claudeCall.arguments),
              usedModel: modelName));
        }
      } else {
        final text = response.text ?? '';
        await _persistAssistantMessage(text);
        if (cachedConversationId != null && event.userId != null) {
          await _addMessageSafe(
              conversationId: cachedConversationId, text: text, senderId: 'ai');
        }
        emit(CopilotResponseGenerated(text, usedModel: modelName));
      }
    }
    // Default: just generate text response
    else {
      final response = await service.generateResponse(
        queryWithContext,
        messageHistory: messageHistory,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      await _persistAssistantMessage(response);
      if (cachedConversationId != null && event.userId != null) {
        await _addMessageSafe(
            conversationId: cachedConversationId,
            text: response,
            senderId: 'ai');
      }
      emit(CopilotResponseGenerated(response, usedModel: modelName));
    }
  }

  Future<void> _onUploadImage(
    UploadImageEvent event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotLoading());
    try {
      // Use AI Router to get the optimal service for image queries
      final service = await routerService.getServiceForQuery(
        query: event.text,
        clinicId: event.clinicId,
        forcePremium: event.forcePremium ?? false,
      );

      // Append timestamp for temporal context
      final textWithContext =
          '${event.text}\n\n${AIContextProvider.getTimestamp()}';

      final response = await service.generateResponseWithImage(
        textWithContext,
        event.imageBytes,
        clinicId: event.clinicId,
        userId: event.userId,
      );
      emit(CopilotResponseGenerated(response));
    } catch (e) {
      if (e is Failure) {
        emit(_mapFailureToMessage(e));
      } else {
        emit(CopilotError(e.toString()));
      }
    }
  }

  Future<void> _onCacheMessages(
    CacheMessagesEvent event,
    Emitter<CopilotState> emit,
  ) async {
    final messagesJson = jsonEncode(event.messages);
    await _retryStorage(
      () => secureStorage.write(key: 'cachedMessages', value: messagesJson),
    );
    if (event.conversationId != null) {
      await _retryStorage(
        () => secureStorage.write(
            key: 'cachedConversationId', value: event.conversationId),
      );
    }
  }

  Future<void> _onLoadCachedMessages(
    LoadCachedMessagesEvent event,
    Emitter<CopilotState> emit,
  ) async {
    final messagesJson =
        await _retryStorage(() => secureStorage.read(key: 'cachedMessages')) ??
            '[]';
    final conversationId = await _retryStorage(
        () => secureStorage.read(key: 'cachedConversationId'));

    final List<dynamic> decodedMessages = jsonDecode(messagesJson);
    final messages = decodedMessages
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
    emit(CachedMessagesLoaded(messages, conversationId: conversationId));
  }

  Future<void> _onStartNewChat(
    StartNewChatEvent event,
    Emitter<CopilotState> emit,
  ) async {
    await _retryStorage(() => secureStorage.delete(key: 'cachedMessages'));
    await _retryStorage(
        () => secureStorage.delete(key: 'cachedConversationId'));
    emit(NewChatStarted());
  }

  CopilotState _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return CopilotError('Server Failure: ${failure.message}');
      case CacheFailure _:
        return CopilotError('Cache Failure: ${failure.message}');
      default:
        return const CopilotError('Unexpected Error');
    }
  }

  void _onUpdateCopilotSettings(
    UpdateCopilotSettingsEvent event,
    Emitter<CopilotState> emit,
  ) {
    debugPrint(
        '[CopilotBloc] Updating required fields for all services: ${event.requiredFields}');
    geminiService.updateModelConfig(event.requiredFields);
    gptService.updateModelConfig(event.requiredFields);
    claudeService.updateModelConfig(event.requiredFields);
    vertexAIService.updateModelConfig(event.requiredFields);
    deepSeekService.updateModelConfig(event.requiredFields);
    qwenService.updateModelConfig(event.requiredFields);
  }

  void _onStopGeneration(
    StopGenerationEvent event,
    Emitter<CopilotState> emit,
  ) {
    debugPrint('[CopilotBloc] Generation stopped by user');
    emit(CopilotGenerationStopped());
  }
}
