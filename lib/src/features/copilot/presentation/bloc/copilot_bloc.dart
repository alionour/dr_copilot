import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot/services/vertex_ai_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
      Object response;
      if (event.selectedModel == 'MedPaLM') {
        response = await vertexAIService.getMedPaLMResponse(event.query);
      } else if (event.selectedModel == 'GPT') {
        response = await gptService.getGPTResponse(event.query);
      } else if (event.selectedModel == 'DeepSeek') {
        response = await deepSeekService.getDeepSeekResponse(event.query);
      } else if (event.selectedModel == 'Qwen') {
        response = await qwenService.getQwenResponse(event.query);
      } else if (event.selectedModel == 'Claude') {
        response = await claudeService.getClaudeResponse(event.query);
      } else {
        response = await geminiService.getGeminiResponse(event.query);
      }
      emit(CopilotResponseGenerated(response));
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
    try {
      GeminiResponse response;
      Uint8List fileBytes = event.imageBytes;
      response =
          await geminiService.getGeminiResponseFromBytes(fileBytes, event.text);
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
