import 'dart:convert';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/vertex_ai_service.dart';
import 'package:equatable/equatable.dart';
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
  final FlutterSecureStorage secureStorage;

  CopilotBloc({
    required this.vertexAIService,
    required this.gptService,
    required this.geminiService,
    required this.deepSeekService,
    required this.qwenService,
    required this.claudeService,
    required this.secureStorage,
  }) : super(CopilotInitial()) {
    on<GenerateResponseEvent>(_onGenerateResponse);
    on<UploadImageEvent>(_onUploadImage);
    on<CacheMessagesEvent>(_onCacheMessages);
    on<LoadCachedMessagesEvent>(_onLoadCachedMessages);
    on<StartNewChatEvent>(_onStartNewChat);
  }

  AIService _getService(String modelName) {
    // Map internal storage keys to service names
    switch (modelName.toLowerCase()) {
      case 'openai':
        return gptService;
      case 'claude':
        return claudeService;
      case 'gemini':
      default:
        return geminiService;
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
      // Read selected model from secure storage with retry
      final selectedModel =
          await _retryStorage(
            () => secureStorage.read(key: 'selected_ai_model'),
          ) ??
          'gemini';
      final service = _getService(selectedModel);

      // Special handling for Gemini to support function calling which returns a different type
      if (service is GeminiService) {
        final response = await service.getGeminiResponse(
          event.query,
          messageHistory: event.messageHistory,
          clinicId: event.clinicId,
          userId: event.userId,
        );
        final functionCalls = response.functionCalls;
        if (functionCalls.isNotEmpty) {
          emit(CopilotFunctionCall(functionCalls.first));
        } else {
          emit(CopilotResponseGenerated(response.text ?? ''));
        }
      } else {
        final response = await service.generateResponse(
          event.query,
          messageHistory: event.messageHistory,
          clinicId: event.clinicId,
          userId: event.userId,
        );
        emit(CopilotResponseGenerated(response));
      }
    } catch (e) {
      if (e is Failure) {
        emit(_mapFailureToMessage(e));
      } else {
        emit(CopilotError(e.toString()));
      }
    }
  }

  Future<void> _onUploadImage(
    UploadImageEvent event,
    Emitter<CopilotState> emit,
  ) async {
    emit(CopilotLoading());
    try {
      // Read selected model from secure storage with retry
      final selectedModel =
          await _retryStorage(
            () => secureStorage.read(key: 'selected_ai_model'),
          ) ??
          'gemini';
      final service = _getService(selectedModel);
      final response = await service.generateResponseWithImage(
        event.text,
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
  }

  Future<void> _onLoadCachedMessages(
    LoadCachedMessagesEvent event,
    Emitter<CopilotState> emit,
  ) async {
    final messagesJson =
        await _retryStorage(() => secureStorage.read(key: 'cachedMessages')) ??
        '[]';
    final List<dynamic> decodedMessages = jsonDecode(messagesJson);
    final messages = decodedMessages
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
    emit(CachedMessagesLoaded(messages));
  }

  Future<void> _onStartNewChat(
    StartNewChatEvent event,
    Emitter<CopilotState> emit,
  ) async {
    await _retryStorage(() => secureStorage.delete(key: 'cachedMessages'));
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
}
