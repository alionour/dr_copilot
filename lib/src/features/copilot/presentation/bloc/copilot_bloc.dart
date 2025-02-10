import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot/services/vertex_ai_service.dart';
import 'package:flutter/foundation.dart';

part 'copilot_event.dart';
part 'copilot_state.dart';

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  final VertexAIService vertexAIService;
  final GPTService gptService;
  final GeminiService geminiService;
  final DeepSeekService deepSeekService;
  final QwenService qwenService;
  final ClaudeService claudeService;

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
    on<StartNewChatEvent>(_onStartNewChat);
  }

  void _onGenerateResponse(
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
      emit(CopilotResponseGenerated(response: response));
    } catch (e) {
      emit(CopilotError(error: e.toString()));
    }
  }

  void _onUploadImage(
      UploadImageEvent event, Emitter<CopilotState> emit) async {
    emit(CopilotLoading());
    try {
      GeminiResponse response;
      Uint8List fileBytes = event.imageBytes;
      response =
          await geminiService.getGeminiResponseFromBytes(fileBytes, event.text);
      emit(CopilotResponseGenerated(response: response));
    } catch (e) {
      emit(CopilotError(error: e.toString()));
    }
  }

  void _onStartNewChat(StartNewChatEvent event, Emitter<CopilotState> emit) {
    emit(CopilotInitial());
  }

  CopilotState _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return CopilotError(error: 'Server Failure: ${failure.message}');
      case CacheFailure _:
        return CopilotError(error: 'Cache Failure: ${failure.message}');
      default:
        return CopilotError(error: 'Unexpected Error');
    }
  }
}
