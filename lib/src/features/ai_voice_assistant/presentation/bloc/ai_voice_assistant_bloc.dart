import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:equatable/equatable.dart';

part 'ai_voice_assistant_event.dart';
part 'ai_voice_assistant_state.dart';

class AiVoiceAssistantBloc
    extends Bloc<AiVoiceAssistantEvent, AiVoiceAssistantState> {
  final SpeechRecognitionDatasource _speechRecognitionDatasource;
  final TextToSpeechDatasource _textToSpeechDatasource;
  final CommandParserService _commandParserService;
  StreamSubscription<String>? _speechSubscription;

  AiVoiceAssistantBloc(
    this._speechRecognitionDatasource,
    this._textToSpeechDatasource,
    this._commandParserService,
  ) : super(AiVoiceAssistantInitial()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<TextChangedEvent>(_onTextChanged);
    on<ProcessCommandEvent>(_onProcessCommand);
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStartListening(
      StartListeningEvent event, Emitter<AiVoiceAssistantState> emit) async {
    emit(const AiVoiceAssistantListening(''));
    // TODO: Get audio stream from microphone
    final audioStream = Stream<List<int>>.empty();
    _speechSubscription =
        _speechRecognitionDatasource.startListening(audioStream).listen((text) {
      add(TextChangedEvent(text));
    });
  }

  void _onStopListening(
      StopListeningEvent event, Emitter<AiVoiceAssistantState> emit) {
    _speechSubscription?.cancel();
    emit(AiVoiceAssistantInitial());
  }

  void _onTextChanged(
      TextChangedEvent event, Emitter<AiVoiceAssistantState> emit) {
    emit(AiVoiceAssistantListening(event.text));
  }

  Future<void> _onProcessCommand(
      ProcessCommandEvent event, Emitter<AiVoiceAssistantState> emit) async {
    emit(AiVoiceAssistantProcessing());
    try {
      await _commandParserService.parseCommand(event.command);
      const successMessage = 'Command processed successfully.';
      emit(const AiVoiceAssistantSuccess(successMessage));
      await _textToSpeechDatasource.speak(successMessage);
    } catch (e) {
      final errorMessage = 'Error processing command: $e';
      emit(AiVoiceAssistantError(errorMessage));
      await _textToSpeechDatasource.speak(errorMessage);
    }
  }
}
