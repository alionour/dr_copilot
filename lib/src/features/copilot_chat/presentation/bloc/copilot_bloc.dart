import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/vertex_ai_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'copilot_event.dart';
part 'copilot_state.dart';

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  final VertexAIService vertexAIService;
  final GPTService gptService;
  final GeminiService geminiService;
  final DeepSeekService deepSeekService;
  final QwenService qwenService;
  final ClaudeService claudeService;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  CopilotBloc({
    required this.vertexAIService,
    required this.gptService,
    required this.geminiService,
    required this.deepSeekService,
    required this.qwenService,
    required this.claudeService,
  }) : super(CopilotInitial()) {
    on<GenerateResponseEvent>(_onGenerateResponse);
    on<UploadImageEvent>(_onUploadImage);
    on<CacheMessagesEvent>(_onCacheMessages);
    on<LoadCachedMessagesEvent>(_onLoadCachedMessages);
    on<StartNewChatEvent>(_onStartNewChat);
  }

  Future<void> _onGenerateResponse(
      GenerateResponseEvent event, Emitter<CopilotState> emit) async {
    emit(CopilotLoading());
    try {
      if (event.selectedModel == 'MedPaLM') {
        final response = await vertexAIService.getMedPaLMResponse(
          event.query,
          messageHistory: event.messageHistory,
        );
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'GPT') {
        final response = await gptService.getGPTResponse(
          event.query,
          messageHistory: event.messageHistory,
        );
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'DeepSeek') {
        final response = await deepSeekService.getDeepSeekResponse(
          event.query,
          messageHistory: event.messageHistory,
        );
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'Qwen') {
        final response = await qwenService.getQwenResponse(
          event.query,
          messageHistory: event.messageHistory,
        );
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'Claude') {
        final response = await claudeService.getClaudeResponse(
          event.query,
          messageHistory: event.messageHistory,
        );
        emit(CopilotResponseGenerated(response));
      } else {
        final response = await geminiService.getGeminiResponse(
          event.query,
          messageHistory: event.messageHistory,
        );
        final functionCalls = response.functionCalls;
        if (functionCalls.isNotEmpty) {
          emit(CopilotFunctionCall(functionCalls.first));
        } else {
          emit(CopilotResponseGenerated(response.text ?? ''));
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

  Future<void> _onUploadImage(
      UploadImageEvent event, Emitter<CopilotState> emit) async {
    emit(CopilotLoading());
    if (event.selectedModel == 'Gemini') {
      emit(const CopilotError('Image upload is not supported for Gemini model at the moment.'));
      return;
    }
    try {
      if (event.selectedModel == 'MedPaLM') {
        final response = await vertexAIService.getMedPaLMResponse(event.text);
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'GPT') {
        final response = await gptService.getGPTResponse(event.text);
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'DeepSeek') {
        final response = await deepSeekService.getDeepSeekResponse(event.text);
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'Qwen') {
        final response = await qwenService.getQwenResponse(event.text);
        emit(CopilotResponseGenerated(response));
      } else if (event.selectedModel == 'Claude') {
        final response = await claudeService.getClaudeResponse(event.text);
        emit(CopilotResponseGenerated(response));
      } else {
        // This part should not be reached if the model is Gemini.
        emit(const CopilotError('Unsupported model for image upload.'));
      }
    } catch (e) {
      if (e is Failure) {
        emit(_mapFailureToMessage(e));
      } else {
        emit(CopilotError(e.toString()));
      }
    }
  }

  Future<void> _onCacheMessages(
      CacheMessagesEvent event, Emitter<CopilotState> emit) async {
    final messagesJson = jsonEncode(event.messages);
    await secureStorage.write(key: 'cachedMessages', value: messagesJson);
  }

  Future<void> _onLoadCachedMessages(
      LoadCachedMessagesEvent event, Emitter<CopilotState> emit) async {
    final messagesJson =
        await secureStorage.read(key: 'cachedMessages') ?? '[]';
    final List<dynamic> decodedMessages = jsonDecode(messagesJson);
    final messages = decodedMessages
        .map((message) => Map<String, dynamic>.from(message))
        .toList();
    emit(CachedMessagesLoaded(messages));
  }

  Future<void> _onStartNewChat(
      StartNewChatEvent event, Emitter<CopilotState> emit) async {
    await secureStorage.delete(key: 'cachedMessages');
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
