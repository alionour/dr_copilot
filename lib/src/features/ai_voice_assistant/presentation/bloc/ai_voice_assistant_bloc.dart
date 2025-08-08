import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

part 'ai_voice_assistant_event.dart';
part 'ai_voice_assistant_state.dart';

class AiVoiceAssistantBloc
    extends Bloc<AiVoiceAssistantEvent, AiVoiceAssistantState> {
  final SpeechRecognitionDatasource _speechRecognitionDatasource;
  final TextToSpeechDatasource _textToSpeechDatasource;
  final CommandParserService _commandParserService;
  final AudioRecorder _audioRecorder;
  StreamSubscription<String>? _speechSubscription;

  AiVoiceAssistantBloc(
    this._speechRecognitionDatasource,
    this._textToSpeechDatasource,
    this._commandParserService,
    this._audioRecorder,
  ) : super(const AiVoiceAssistantInitial()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<TextChangedEvent>(_onTextChanged);
    on<ProcessCommandEvent>(_onProcessCommand);
    on<AddMessageToHistoryEvent>(_onAddMessageToHistory);
  }

  @override
  void onEvent(AiVoiceAssistantEvent event) {
    super.onEvent(event);
    debugPrint('AiVoiceAssistantBloc: onEvent: $event');
  }

  @override
  void onTransition(
      Transition<AiVoiceAssistantEvent, AiVoiceAssistantState> transition) {
    super.onTransition(transition);
    debugPrint('AiVoiceAssistantBloc: onTransition: $transition');
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    _audioRecorder.dispose();
    return super.close();
  }

  Future<void> _onStartListening(
      StartListeningEvent event, Emitter<AiVoiceAssistantState> emit) async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final audioStream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ));
        emit(AiVoiceAssistantListening('',
            conversationHistory: state.conversationHistory));
        _speechSubscription = _speechRecognitionDatasource
            .startListening(audioStream)
            .listen((text) {
          add(TextChangedEvent(text));
        }, onError: (error) {
          debugPrint('Error from speech stream: $error');
          add(AddMessageToHistoryEvent('Error: $error'));
          emit(AiVoiceAssistantError('Error from speech stream: $error',
              conversationHistory: state.conversationHistory));
        });
      } else {
        add(const AddMessageToHistoryEvent('Error: Microphone permission not granted.'));
        emit(const AiVoiceAssistantError('Microphone permission not granted.'));
      }
    } catch (e) {
      debugPrint('Error starting to listen: $e');
      add(AddMessageToHistoryEvent('Error: $e'));
      emit(AiVoiceAssistantError('Error starting to listen: $e',
          conversationHistory: state.conversationHistory));
    }
  }

  void _onStopListening(
      StopListeningEvent event, Emitter<AiVoiceAssistantState> emit) {
    _audioRecorder.stop();
    _speechSubscription?.cancel();
    emit(AiVoiceAssistantInitial(
        conversationHistory: state.conversationHistory));
  }

  void _onTextChanged(
      TextChangedEvent event, Emitter<AiVoiceAssistantState> emit) {
    emit(AiVoiceAssistantListening(event.text,
        conversationHistory: state.conversationHistory));
  }

  Future<void> _onProcessCommand(
      ProcessCommandEvent event, Emitter<AiVoiceAssistantState> emit) async {
    add(AddMessageToHistoryEvent('You: ${event.command}'));
    emit(AiVoiceAssistantProcessing(
        conversationHistory: state.conversationHistory));
    try {
      await _commandParserService.parseCommand(event.command);
      const successMessage = 'Command processed successfully.';
      add(AddMessageToHistoryEvent('AI: $successMessage'));
      emit(AiVoiceAssistantSuccess(successMessage,
          conversationHistory: state.conversationHistory));
      await _textToSpeechDatasource.speak(successMessage);
    } catch (e) {
      final errorMessage = 'Error processing command: $e';
      add(AddMessageToHistoryEvent('AI: $errorMessage'));
      emit(AiVoiceAssistantError(errorMessage,
          conversationHistory: state.conversationHistory));
      await _textToSpeechDatasource.speak(errorMessage);
    }
  }

  void _onAddMessageToHistory(
      AddMessageToHistoryEvent event, Emitter<AiVoiceAssistantState> emit) {
    final newHistory = List<String>.from(state.conversationHistory)
      ..add(event.message);
    emit(state.copyWith(conversationHistory: newHistory));
  }
}

extension on AiVoiceAssistantState {
  AiVoiceAssistantState copyWith({
    List<String>? conversationHistory,
  }) {
    if (this is AiVoiceAssistantInitial) {
      return AiVoiceAssistantInitial(
          conversationHistory:
              conversationHistory ?? this.conversationHistory);
    } else if (this is AiVoiceAssistantListening) {
      return AiVoiceAssistantListening(
          (this as AiVoiceAssistantListening).recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory);
    } else if (this is AiVoiceAssistantProcessing) {
      return AiVoiceAssistantProcessing(
          conversationHistory:
              conversationHistory ?? this.conversationHistory);
    } else if (this is AiVoiceAssistantSpeaking) {
      return AiVoiceAssistantSpeaking(
          (this as AiVoiceAssistantSpeaking).textToSpeak,
          conversationHistory:
              conversationHistory ?? this.conversationHistory);
    } else if (this is AiVoiceAssistantSuccess) {
      return AiVoiceAssistantSuccess((this as AiVoiceAssistantSuccess).message,
          conversationHistory:
              conversationHistory ?? this.conversationHistory);
    } else if (this is AiVoiceAssistantError) {
      return AiVoiceAssistantError((this as AiVoiceAssistantError).message,
          conversationHistory:
              conversationHistory ?? this.conversationHistory);
    }
    return this;
  }
}
