import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot/services/vertex_ai_service.dart';
import 'package:flutter/foundation.dart';

part 'copilot_event.dart';
part 'copilot_state.dart';

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  final VertexAIService vertexAIService;
  final GPTService gptService;
  final GeminiService geminiService;

  CopilotBloc({
    required this.vertexAIService,
    required this.gptService,
    required this.geminiService,
  }) : super(CopilotInitial()) {
    on<GenerateResponseEvent>(_onGenerateResponse);
    on<UploadImageEvent>(_onUploadImage);
    on<StartNewChatEvent>(_onStartNewChat);
  }

  void _onGenerateResponse(
      GenerateResponseEvent event, Emitter<CopilotState> emit) async {
    emit(CopilotLoading());
    try {
      String response;
      if (event.selectedModel == 'MedPaLM') {
        response = await vertexAIService.getMedPaLMResponse(event.query);
      } else if (event.selectedModel == 'GPT') {
        response = await gptService.getGPTResponse(event.query);
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
      String response;
      if (kIsWeb) {
        // Handle web file upload
        Uint8List fileBytes = event.imageBytes;
        if (event.selectedModel == 'MedPaLM') {
          response =
              await vertexAIService.getMedPaLMResponseFromBytes(fileBytes);
        } else if (event.selectedModel == 'GPT') {
          response = await gptService.getGPTResponseFromBytes(fileBytes);
        } else {
          response = await geminiService.getGeminiResponseFromBytes(fileBytes);
        }
      } else {
        // Handle non-web file upload
        String filePath = event.imageBytes.toString();
        if (event.selectedModel == 'MedPaLM') {
          response = await vertexAIService.getMedPaLMResponse(filePath);
        } else if (event.selectedModel == 'GPT') {
          response = await gptService.getGPTResponse(filePath);
        } else {
          response = await geminiService.getGeminiResponse(filePath);
        }
      }
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
