import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google;
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_tools.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/live_chat_state.dart';

/// A service that manages a live conversational session with Gemini via Firebase AI SDK.
/// Collapses STT, LLM, and TTS into a single bidirectional WebSocket session.
class GeminiLiveService {
  static const String _liveModelName =
      'gemini-2.5-flash-native-audio-preview-12-2025';

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer()
    ..setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        audioFocus: AndroidAudioFocus.gainTransient,
      ),
    ));
  LiveSession? _session;
  StreamSubscription? _recorderSubscription;
  bool _isClosingSession = false;

  final StreamController<LiveChatState> _stateController =
      StreamController.broadcast();
  final StreamController<String> _transcriptController =
      StreamController.broadcast();
  final StreamController<double> _audioLevelController =
      StreamController.broadcast();

  LiveChatState _currentState = LiveChatState.idle;

  final List<_AudioChunk> _audioQueue = [];
  bool _isPlayingAudio = false;

  Completer<void>? _currentPlaybackCompleter;

  // Callbacks and Dependencies
  final Future<String?> Function() getClinicId;
  final FunctionCallHandler functionCallHandler;
  String currentLocale;
  Function(String formType, Map<String, dynamic> initialData)? onFormRequested;

  final List<String> _interactiveTools = const [
    'add_patient',
    'edit_patient',
    'add_session',
    'edit_session',
    'add_evaluation',
    'edit_evaluation'
  ];

  GeminiLiveService({
    required this.getClinicId,
    required this.functionCallHandler,
    this.currentLocale = 'en',
    this.onFormRequested,
  }) {
    // Ensure we are in a clean state
    _setState(LiveChatState.idle);
  }

  Stream<LiveChatState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<double> get audioLevelStream => _audioLevelController.stream;
  LiveChatState get currentState => _currentState;

  void _setState(LiveChatState state) {
    _currentState = state;
    _stateController.add(state);
    debugPrint('[GeminiLive] State: $state');
  }

  /// Establishes the connection to the Gemini Live model via Firebase.
  Future<void> startSession() async {
    if (_session != null) return;

    _setState(LiveChatState.processing);

    try {
      final clinicId = await getClinicId();

      final firebaseAI = FirebaseAI.googleAI();
      final model = firebaseAI.liveGenerativeModel(
        model: _liveModelName,
        liveGenerationConfig: LiveGenerationConfig(
          responseModalities: [ResponseModalities.audio],
          speechConfig: SpeechConfig(
            voiceName: 'Puck',
          ),
        ),
        systemInstruction: Content.system(
          'You are "Dr. AI", a professional medical assistant for a clinic manager app. '
          'Your tone is helpful, concise, and professional. '
          'You can help manage patients, sessions, and evaluations. '
          'Current Clinic ID: ${clinicId ?? "Unknown"}. '
          'User locale: $currentLocale. '
          'When performing actions like adding a patient or session, you should prepare the form for the user. '
          'When you call a tool like "add_patient", a form will be shown to the user. '
          'Confirm that you have prepared the form briefly.',
        ),
        tools: getFirebaseAITools(),
      );

      _session = await model.connect();
      _setState(LiveChatState.idle);

      unawaited(_listenToSession());
      await _startRecording();
    } catch (e) {
      debugPrint('[GeminiLive] Connection failed: $e');
      await _closeLiveSession(LiveChatState.error);
    }
  }

  /// Stops the current session and releases resources.
  Future<void> stopSession() async {
    await _closeLiveSession(LiveChatState.idle);
  }

  Future<void> _closeLiveSession(LiveChatState nextState) async {
    if (_isClosingSession) return;
    _isClosingSession = true;

    try {
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      await _recorder.stop();
      await _session?.close();
      _session = null;
      await _clearAudioQueue();
      await _player.stop();
      _setState(nextState);
    } catch (e) {
      debugPrint('[GeminiLive] Failed to close live session cleanly: $e');
      _session = null;
      _setState(nextState);
    } finally {
      _isClosingSession = false;
    }
  }

  Future<void> _listenToSession() async {
    while (_session != null && !_isClosingSession) {
      try {
        await for (final event in _session!.receive()) {
          await _handleServerEvent(event);
        }
      } catch (e) {
        debugPrint('[GeminiLive] Session listen error: $e');
        break;
      }
    }
  }

  Future<void> _handleServerEvent(LiveServerResponse event) async {
    final message = event.message;
    switch (message) {
      case LiveServerContent():
        // Handle user speech transcription
        if (message.inputTranscription?.text != null &&
            message.inputTranscription!.text!.isNotEmpty) {
          final text = message.inputTranscription!.text!;
          debugPrint('[Transcript] USER: $text');
          _transcriptController.add('__USER__:$text');
        }

        // Handle AI speech transcription
        if (message.outputTranscription?.text != null &&
            message.outputTranscription!.text!.isNotEmpty) {
          final text = message.outputTranscription!.text!;
          debugPrint('[Transcript] AI: $text');
          _transcriptController.add('__AI__:$text');
        }

        // Handle interruption
        if (message.interrupted == true) {
          debugPrint('[GeminiLive] <<< Server interrupted >>>');
          await _clearAudioQueue();
        }

        if (message.turnComplete == true) {
          debugPrint('[GeminiLive] turnComplete');
          unawaited(_ensureRecording());
          if (!_isPlayingAudio &&
              (_currentState == LiveChatState.speaking ||
                  _currentState == LiveChatState.processing)) {
            _setState(LiveChatState.listening);
          }
        }

        final modelTurn = message.modelTurn;
        if (modelTurn != null) {
          for (final part in modelTurn.parts) {
            if (part is InlineDataPart) {
              _playAudioChunk(part.bytes, part.mimeType);
            } else if (part is TextPart) {
              if (message.outputTranscription?.text == null) {
                debugPrint('[Transcript] AI (text): ${part.text}');
                _transcriptController.add('__AI__:${part.text}');
              }
            }
          }
        }
      case LiveServerToolCall():
        debugPrint('[GeminiLive] === Tool call received ===');
        try {
          final responses = <FunctionResponse>[];
          final functionCalls = message.functionCalls;
          debugPrint('[GeminiLive] functionCalls count: ${functionCalls?.length}');

          if (functionCalls != null) {
            for (final call in functionCalls) {
              debugPrint('[GeminiLive] -> call: ${call.name} args: ${call.args}');
              debugPrint('[GeminiLive] -> interactive? ${_interactiveTools.contains(call.name)} onFormRequested? ${onFormRequested != null}');

              if (_interactiveTools.contains(call.name) &&
                  onFormRequested != null) {
                // Show form instead of executing directly
                debugPrint('[GeminiLive] -> showing form for ${call.name}');
                onFormRequested!(call.name, call.args);
                responses.add(FunctionResponse(call.name, {
                  'status': 'form_shown',
                  'message':
                      'I have prepared the form for you. Please review and confirm.'
                }));
              } else {
                _setState(LiveChatState.processing);
                // Convert to google_generative_ai.FunctionCall for the handler
                final googleCall = google.FunctionCall(call.name, call.args);
                debugPrint('[GeminiLive] -> executing handler for ${call.name}');
                final stopwatch = Stopwatch()..start();
                final result =
                    await functionCallHandler.handleFunctionCall(googleCall);
                stopwatch.stop();
                debugPrint('[GeminiLive] <- handler returned in ${stopwatch.elapsedMilliseconds}ms keys: ${result.keys.join(", ")}');
                debugPrint('[GeminiLive] <- handler result error? ${result.containsKey("error")}');
                responses.add(FunctionResponse(call.name, result));
              }
            }
          }
          debugPrint('[GeminiLive] sending ${responses.length} tool response(s)');
          await _session?.sendToolResponse(responses);
          debugPrint('[GeminiLive] tool response sent, state -> listening');
          _setState(LiveChatState.listening);
        } catch (e, stack) {
          debugPrint('[GeminiLive] Tool call error: $e');
          debugPrint('[GeminiLive] Stack: $stack');
          _setState(LiveChatState.listening);
        }
      default:
        break;
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      debugPrint('[GeminiLive] Microphone permission denied');
      _setState(LiveChatState.error);
      return;
    }

    _setState(LiveChatState.listening);

    final stream = await _recorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
      echoCancel: true,
      noiseSuppress: true,
      audioInterruption: AudioInterruptionMode.none,
      androidConfig: AndroidRecordConfig(
        audioSource: AndroidAudioSource.voiceCommunication,
        speakerphone: true,
        audioManagerMode: AudioManagerMode.modeInCommunication,
      ),
    ));

    _recorderSubscription = stream.listen((data) async {
      final audioBytes = Uint8List.fromList(data);

      // Calculate levels for the UI visualizer
      final level = _calculateRms(audioBytes);
      _audioLevelController.add(level);

      final session = _session;
      if (session != null) {
        try {
          await session.sendAudioRealtime(
            InlineDataPart('audio/pcm;rate=16000', audioBytes),
          );
        } catch (e) {
          debugPrint('[GeminiLive] Failed to send audio chunk: $e');
          unawaited(_closeLiveSession(LiveChatState.error));
        }
      }
    });
  }

  static bool _isPcmFormat(String mimeType) {
    return mimeType.startsWith('audio/L16') ||
        mimeType.startsWith('audio/pcm') ||
        mimeType.startsWith('audio/l16');
  }

  static Uint8List _wrapWithWavHeader(Uint8List pcmData,
      {int sampleRate = 24000}) {
    const bitsPerSample = 16;
    const numChannels = 1;
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmData.length;
    final headerSize = 44;

    final wav = Uint8List(headerSize + dataSize);

    // RIFF chunk descriptor
    wav[0] = 0x52;
    wav[1] = 0x49;
    wav[2] = 0x46;
    wav[3] = 0x46; // "RIFF"
    wav[4] = (36 + dataSize) & 0xFF;
    wav[5] = ((36 + dataSize) >> 8) & 0xFF;
    wav[6] = ((36 + dataSize) >> 16) & 0xFF;
    wav[7] = ((36 + dataSize) >> 24) & 0xFF;
    wav[8] = 0x57;
    wav[9] = 0x41;
    wav[10] = 0x56;
    wav[11] = 0x45; // "WAVE"

    // fmt sub-chunk
    wav[12] = 0x66;
    wav[13] = 0x6D;
    wav[14] = 0x74;
    wav[15] = 0x20; // "fmt "
    wav[16] = 16;
    wav[17] = 0;
    wav[18] = 0;
    wav[19] = 0; // chunk size = 16
    wav[20] = 1;
    wav[21] = 0; // PCM format
    wav[22] = numChannels;
    wav[23] = 0; // mono
    wav[24] = sampleRate & 0xFF;
    wav[25] = (sampleRate >> 8) & 0xFF;
    wav[26] = (sampleRate >> 16) & 0xFF;
    wav[27] = (sampleRate >> 24) & 0xFF;
    wav[28] = byteRate & 0xFF;
    wav[29] = (byteRate >> 8) & 0xFF;
    wav[30] = (byteRate >> 16) & 0xFF;
    wav[31] = (byteRate >> 24) & 0xFF;
    wav[32] = blockAlign;
    wav[33] = 0;
    wav[34] = bitsPerSample;
    wav[35] = 0;

    // data sub-chunk
    wav[36] = 0x64;
    wav[37] = 0x61;
    wav[38] = 0x74;
    wav[39] = 0x61; // "data"
    wav[40] = dataSize & 0xFF;
    wav[41] = (dataSize >> 8) & 0xFF;
    wav[42] = (dataSize >> 16) & 0xFF;
    wav[43] = (dataSize >> 24) & 0xFF;

    // PCM data
    wav.setRange(44, wav.length, pcmData);

    return wav;
  }

  void _playAudioChunk(Uint8List audioData, String mimeType) {
    if (_currentState != LiveChatState.speaking) {
      _setState(LiveChatState.speaking);
    }

    int? sampleRate;
    if (_isPcmFormat(mimeType)) {
      sampleRate = 24000;
      final rateMatch = RegExp(r'rate=(\d+)').firstMatch(mimeType);
      if (rateMatch != null) {
        sampleRate = int.tryParse(rateMatch.group(1)!) ?? 24000;
      }
    }

    _audioQueue.add(_AudioChunk(audioData, mimeType, sampleRate: sampleRate));

    if (!_isPlayingAudio) {
      _isPlayingAudio = true;
      _playNextAudio();
    }
  }

  Future<void> _playNextAudio() async {
    if (_audioQueue.isEmpty) {
      _isPlayingAudio = false;
      // Always go back to listening after playback finishes
      if (_currentState != LiveChatState.listening) {
        debugPrint('[GeminiLive] Playback finished, returning to listening');
        _setState(LiveChatState.listening);
      }
      unawaited(_ensureRecording());
      return;
    }

    // Drain ALL mergeable chunks from the queue to minimize separate play calls
    final firstChunk = _audioQueue.removeAt(0);
    final int? baseRate = firstChunk.sampleRate;
    final String baseMime = firstChunk.mimeType;

    Uint8List playBytes = firstChunk.bytes;
    String playMime = baseMime;

    if (baseRate != null) {
      final List<Uint8List> toMerge = [firstChunk.bytes];
      final List<_AudioChunk> deferred = [];
      while (_audioQueue.isNotEmpty) {
        final chunk = _audioQueue.removeAt(0);
        if (chunk.sampleRate == baseRate && chunk.mimeType == baseMime) {
          toMerge.add(chunk.bytes);
        } else {
          deferred.add(chunk);
        }
      }
      _audioQueue.addAll(deferred);

      final totalLength = toMerge.fold(0, (sum, b) => sum + b.length);
      final merged = Uint8List(totalLength);
      int offset = 0;
      for (final b in toMerge) {
        merged.setRange(offset, offset + b.length, b);
        offset += b.length;
      }
      debugPrint(
          '[GeminiLive] Merged ${toMerge.length} PCM chunks into ${merged.length} bytes');

      playBytes = _wrapWithWavHeader(merged, sampleRate: baseRate);
      playMime = 'audio/wav';
    }

    debugPrint(
        '[GeminiLive] Playing: ${playBytes.length} bytes, mime: $playMime');

    try {
      _currentPlaybackCompleter = Completer<void>();

      final completionSub = _player.onPlayerComplete.listen((_) {
        if (_currentPlaybackCompleter != null &&
            !_currentPlaybackCompleter!.isCompleted) {
          _currentPlaybackCompleter!.complete();
        }
      });

      await _player.setSourceBytes(playBytes, mimeType: playMime);
      await _player.resume();

      await _currentPlaybackCompleter!.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[GeminiLive] Playback timeout');
        },
      );

      await completionSub.cancel();
    } catch (e) {
      debugPrint('[GeminiLive] Playback error: $e');
    } finally {
      _currentPlaybackCompleter = null;
    }

    _playNextAudio();
  }

  Future<void> _ensureRecording() async {
    if (_recorderSubscription == null || _isClosingSession) return;
    if (!await _recorder.isRecording()) {
      debugPrint('[GeminiLive] Recording stopped, restarting...');
      await _startRecording();
    }
  }

  Future<void> _clearAudioQueue() async {
    debugPrint('[GeminiLive] Clearing audio queue');
    _audioQueue.clear();
    await _player.stop();
    _isPlayingAudio = false;
    if (_currentPlaybackCompleter != null &&
        !_currentPlaybackCompleter!.isCompleted) {
      _currentPlaybackCompleter!.complete();
    }
  }

  double _calculateRms(Uint8List samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0;
    for (int i = 0; i < samples.length; i += 2) {
      if (i + 1 >= samples.length) break;
      // PCM 16-bit little endian
      int sample = (samples[i + 1] << 8) | samples[i];
      if (sample >= 32768) sample -= 65536;
      sum += sample * sample;
    }
    double rms = sqrt(sum / (samples.length / 2));
    // Normalize to 0.0 - 1.0 range based on 16-bit max
    return (rms / 32768.0).clamp(0.0, 1.0);
  }

  Future<void> speak(String text) async {
    // This method is for compatibility with old interface
    // where UI might want to trigger a manual speak.
    try {
      await _session?.sendTextRealtime(text);
    } catch (e) {
      debugPrint('[GeminiLive] Failed to send text: $e');
      await _closeLiveSession(LiveChatState.error);
    }
  }

  void resume() {
    if (_session == null) {
      startSession();
    } else {
      _setState(LiveChatState.listening);
    }
  }

  void dispose() {
    stopSession();
    _stateController.close();
    _transcriptController.close();
    _audioLevelController.close();
  }
}

class _AudioChunk {
  final Uint8List bytes;
  final String mimeType;
  final int? sampleRate;

  _AudioChunk(this.bytes, this.mimeType, {this.sampleRate});
}
