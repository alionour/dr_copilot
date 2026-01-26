import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/abstract_speech_recognition_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/tts_service.dart';
import 'package:audioplayers/audioplayers.dart';
// Actually we probably want to inject the AI service directly or use the Bloc.
// Using Bloc from a Service is tricky. Better to let the UI (Page/Bloc) handle the AI call,
// or have this service invoke a callback/UseCase.
// For "Live Experience", tightly coupling logic here is better.
// Let's assume we pass a callback for "generateResponse".

enum LiveChatState {
  listening,
  processing,
  speaking,
  idle,
}

class LiveChatService {
  final AbstractSpeechRecognitionService _speechService;
  final TtsService _ttsService;

  // Callback to trigger AI response generation
  // Returns a Stream of text chunks (if streaming) or just a Future<String>
  // For now, let's assume Future<String> for simplicity, or we can upgrade to Stream later.
  Future<String> Function(String query)? onGenerateResponse;

  final StreamController<LiveChatState> _stateController =
      StreamController.broadcast();
  final StreamController<String> _transcriptController =
      StreamController.broadcast();
  final StreamController<double> _audioLevelController =
      StreamController.broadcast(); // For visualizer

  StreamSubscription? _speechSubscription;
  StreamSubscription? _playerSubscription;

  LiveChatState _currentState = LiveChatState.idle;

  bool _isInterrupted = false;

  LiveChatService({
    required AbstractSpeechRecognitionService speechService,
    required TtsService ttsService,
  })  : _speechService = speechService,
        _ttsService = ttsService;

  Stream<LiveChatState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<double> get audioLevelStream => _audioLevelController.stream;
  LiveChatState get currentState => _currentState;

  void _setState(LiveChatState state) {
    _currentState = state;
    _stateController.add(state);
    debugPrint('[LiveChat] State changed to: $state');
  }

  Future<void> startSession() async {
    _setState(LiveChatState.listening); // Immediate feedback
    await _speechService.initialize();
    _startListeningLoop();
  }

  Future<void> stopSession() async {
    _speechSubscription?.cancel();
    _playerSubscription?.cancel();
    await _speechService.stopListening();
    await _ttsService.stop();
    _setState(LiveChatState.idle);
  }

  void _startListeningLoop() async {
    _setState(LiveChatState.listening);

    // Listen to speech stream
    // We need to access the real-time stream from speech service.
    // The current SpeechService architecture uses a controller, ensuring we get the updates.

    // We need to implement a "VAD-like" logic or rely on "isFinal" to trigger response.
    // Deepgram "isFinal" is a good proxy for "User finished sentence".

    // Note: To support "Interruption", we need to distinguish:
    // 1. User speaking while Idle/Listening -> Normal flow.
    // 2. User speaking while Speaking -> Interruption.

    // This requires us to be "listening" ALWAYS, even when "speaking".
    // So "Listening" state in our Enum refers to "Waiting for user input main turn".
    // But physically, the mic should be open.

    // Start mic
    final result = await _speechService.startListening();
    result.fold(
        (failure) =>
            debugPrint('[LiveChat] Error starting mic: ${failure.message}'),
        (_) {
      // Subscribe to the stream
      _speechSubscription?.cancel();
      _speechSubscription =
          _speechService.getRealtimeRecognitionStream().listen((event) {
        event.fold((fail) {}, // ignore errors
            (text) {
          // Check for interruption
          // Ignore very short bursts which might be echo/feedback
          if (_currentState == LiveChatState.speaking &&
              text.trim().length > 3) {
            // Logic: If user says something substantial (not just background noise), interrupt.
            // Increased threshold to > 3 chars to prevent self-interruption loops from echo.
            _handleInterruption();
          }

          // Pass partials to UI
          if (text.startsWith('__FINAL__:')) {
            final finalText = text.substring(10);
            _transcriptController.add(finalText);

            // If we are in listening mode, this triggers the turn
            if (_currentState == LiveChatState.listening) {
              _processUserQuery(finalText);
            }
          } else {
            _transcriptController.add(text);
            // Simulate audio level from text length/change?
            // Real audio level would need `audio_waveforms` package or raw audio stream access.
            // For now, generate fake levels based on activity.
            _audioLevelController.add(0.5);
          }
        });
      });
    });
  }

  void _handleInterruption() async {
    if (_isInterrupted) return;
    _isInterrupted = true;
    debugPrint('[LiveChat] Interruption detected!');

    await _ttsService.stop();
    _setState(LiveChatState.listening); // Go back to listening immediately

    // Give a small delay before clearing interrupt flag to avoid self-triggering
    Future.delayed(const Duration(seconds: 1), () {
      _isInterrupted = false;
    });
  }

  Future<void> _processUserQuery(String query) async {
    if (query.trim().isEmpty) return;

    // Stop listening temporarily? No, we want interruption.
    // But we shouldn't trigger another query while processing one.
    _setState(LiveChatState.processing);

    try {
      if (onGenerateResponse != null) {
        final responseText = await onGenerateResponse!(query);

        // Clear the transcript buffer after successfully processing the query
        // This prevents accumulation of previous questions in subsequent turns
        _speechService.clearAccumulatedTranscript();

        if (_currentState == LiveChatState.processing) {
          // If we haven't been interrupted (reset to listening), proceed to speak
          _speakResponse(responseText);
        }
      }
    } catch (e) {
      debugPrint('[LiveChat] AI Processing Error: $e');
      _speechService.clearAccumulatedTranscript(); // Also clear on error
      _setState(LiveChatState.listening);
    }
  }

  Future<void> speak(String text) async {
    await _speakResponse(text);
  }

  void resume() {
    debugPrint('[LiveChat] Resuming session... Current state: $_currentState');
    if (_currentState == LiveChatState.idle) {
      startSession();
    } else {
      _setState(LiveChatState.listening);
    }
  }

  Future<void> _speakResponse(String text) async {
    _setState(LiveChatState.speaking);

    final result = await _ttsService.speak(text);
    result.fold((fail) => _setState(LiveChatState.listening), (_) {
      // Monitor player state to know when finished
      _playerSubscription?.cancel();
      _playerSubscription = _ttsService.playerStateStream.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          if (_currentState == LiveChatState.speaking) {
            // Only return to listening if we were still speaking (not interrupted)
            _setState(LiveChatState.listening);
          }
        }
      });
    });
  }

  void dispose() {
    stopSession();
    _stateController.close();
    _transcriptController.close();
    _audioLevelController.close();
    _ttsService.dispose();
  }
}
