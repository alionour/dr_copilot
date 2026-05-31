import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as google;
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_tools.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/live_chat_state.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/utils/json_sanitizer.dart';

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
  final StreamController<PatientModel?> _activePatientController =
      StreamController.broadcast();

  LiveChatState _currentState = LiveChatState.idle;
  PatientModel? _activePatient;

  final List<_AudioChunk> _audioQueue = [];
  bool _isPlayingAudio = false;
  bool _shouldSendAudio = true;
  bool _resumeAudioOnNextContent = false;

  Completer<void>? _currentPlaybackCompleter;

  // Callbacks and Dependencies
  final Future<String?> Function() getClinicId;
  final FunctionCallHandler functionCallHandler;
  String currentLocale;
  Function(String formType, Map<String, dynamic> initialData)? onFormRequested;
  Function(String toolName, Map<String, dynamic> results)? onQueryResult;

  final List<String> _interactiveTools = const [
    'add_patient',
    'edit_patient',
    'add_session',
    'edit_session',
    'add_evaluation',
    'edit_evaluation'
  ];

  final List<String> _queryTools = const [
    'list_patients',
    'list_sessions',
    'list_evaluations',
    'get_patient',
    'get_session',
    'get_evaluation',
    'select_patient',
    'clear_active_patient'
  ];

  GeminiLiveService({
    required this.getClinicId,
    required this.functionCallHandler,
    this.currentLocale = 'en',
    this.onFormRequested,
    this.onQueryResult,
  }) {
    // Ensure we are in a clean state
    _setState(LiveChatState.idle);
  }

  Stream<LiveChatState> get stateStream => _stateController.stream;
  Stream<String> get transcriptStream => _transcriptController.stream;
  Stream<double> get audioLevelStream => _audioLevelController.stream;
  Stream<PatientModel?> get activePatientStream =>
      _activePatientController.stream;
  LiveChatState get currentState => _currentState;
  PatientModel? get activePatient => _activePatient;

  void setActivePatient(PatientModel? patient) {
    _activePatient = patient;
    _activePatientController.add(patient);
    debugPrint('[GeminiLive] Active Patient: ${patient?.name}');

    // If session is active, notify the AI about the context change
    if (_session != null) {
      if (patient != null) {
        speak(
            "__CONTEXT_UPDATE__: You are now focused on patient ${patient.name} (ID: ${patient.id}). Use this patient for any follow-up actions unless specified otherwise.");
      } else {
        speak(
            "__CONTEXT_UPDATE__: The active patient context has been cleared.");
      }
    }
  }

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
      debugPrint('[GeminiLive] startSession: connecting');
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
          '${_activePatient != null ? "Currently focused on patient: ${_activePatient!.name} (ID: ${_activePatient!.id}). Use this ID for any follow-up actions like adding a session or editing details unless told otherwise." : ""} '
          'When performing actions like adding/editing a patient or session, prepare the form for the user. '
          'When you call a tool like "add_patient" or "edit_patient", a form will be shown to the user. '
          'Confirm that you have prepared the form briefly. '
          'When you call a list/query tool (e.g. list_patients, list_sessions): '
          '1. Clearly state how many items were found. '
          '2. List the items clearly (e.g., "1. Patient Name (Age)"). NEVER speak long IDs/UIDs. '
          'If you need to distinguish between items with identical names, use only the last 4 characters of their ID (e.g., "the one ending in 7B2E"). '
          '3. Ask the user to select one of the items by number or name if they want to perform further actions like editing or adding a session for them. '
          'If no results are found, say so explicitly and offer to help with something else.',
        ),
        tools: getFirebaseAITools(),
      );

      _session = await model.connect();
      _setState(LiveChatState.idle);

      unawaited(_listenToSession());
      await _startRecording();
    } catch (e, stack) {
      debugPrint('[GeminiLive] Connection failed: $e\n$stack');
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
        if (_resumeAudioOnNextContent) {
          _shouldSendAudio = true;
          _resumeAudioOnNextContent = false;
          debugPrint('[GeminiLive] Resuming audio after tool response');
        }
        debugPrint('[GeminiLive] LiveServerContent: turnComplete=${message.turnComplete} modelTurn=${message.modelTurn != null} parts=${message.modelTurn?.parts.length} interrupted=${message.interrupted}');
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
        } else if (message.outputTranscription?.text != null &&
            message.outputTranscription!.text!.isEmpty) {
          debugPrint('[GeminiLive] outputTranscription present but empty');
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
            final partType = part.runtimeType;
            final partInfo = part is TextPart
                ? part.text.substring(0, min(part.text.length, 80))
                : part is InlineDataPart
                    ? '${part.mimeType} ${part.bytes.length}B'
                    : partType.toString();
            debugPrint('[GeminiLive] modelTurn part: $partType $partInfo');
            if (part is InlineDataPart) {
              _playAudioChunk(part.bytes, part.mimeType);
            } else if (part is TextPart) {
              if (message.outputTranscription?.text == null ||
                  message.outputTranscription!.text!.isEmpty) {
                debugPrint('[Transcript] AI (text): ${part.text}');
                _transcriptController.add('__AI__:${part.text}');
              }
            }
          }
        }
      case LiveServerToolCall():
        debugPrint('[GeminiLive] === Tool call received ===');
        _shouldSendAudio = false;
        final responses = <FunctionResponse>[];
        final functionCalls = message.functionCalls;
        try {
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
                responses.add(FunctionResponse(
                  call.name,
                  {
                    'status': 'form_shown',
                    'message':
                        'I have prepared the form for you. Please review and confirm.'
                  },
                  id: call.id,
                ));
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

                // Push to UI if it's a query tool
                if (_queryTools.contains(call.name) && onQueryResult != null) {
                  onQueryResult!(call.name, result);
                }

                // Handle select/clear patient tools specially
                if (call.name == 'select_patient') {
                  final patientData = result['patient'] ?? result;
                  if (patientData is Map<String, dynamic> &&
                      patientData.containsKey('id')) {
                    final patient = PatientModel(
                      id: patientData['id'],
                      name: patientData['name'] ?? '',
                      age: patientData['age'] is int
                          ? patientData['age']
                          : int.tryParse(patientData['age']?.toString() ?? ''),
                      gender: patientData['gender'],
                      ownerId: '',
                      clinicId: '',
                      createdAt: Timestamp.now(),
                    );
                    _activePatient = patient;
                    _activePatientController.add(patient);
                  }
                } else if (call.name == 'clear_active_patient') {
                  _activePatient = null;
                  _activePatientController.add(null);
                }

                // Sanitize the result as a safety net
                responses.add(FunctionResponse(
                  call.name,
                  sanitizeJsonForGemini(result),
                  id: call.id,
                ));
              }
            }
          }
          debugPrint('[GeminiLive] sending ${responses.length} tool response(s)');
          await _session?.sendToolResponse(responses);
          _resumeAudioOnNextContent = true;
          debugPrint('[GeminiLive] tool response sent, waiting for server content');
          _setState(LiveChatState.listening);
        } catch (e, stack) {
          debugPrint('[GeminiLive] !!! Tool call execution error: $e');
          debugPrint('[GeminiLive] Stack: $stack');
          _shouldSendAudio = true;
          if (functionCalls != null && responses.isEmpty) {
            for (final call in functionCalls) {
              final errMap = {
                'error': 'An error occurred while executing ${call.name}: $e',
              };
              debugPrint('[GeminiLive] -> sending error response for ${call.name} (id: ${call.id})');
              responses.add(FunctionResponse(
                call.name,
                errMap,
                id: call.id,
              ));
            }
            await _session?.sendToolResponse(responses);
          }
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
      if (session != null && _shouldSendAudio) {
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
      _shouldSendAudio = false;
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
      _shouldSendAudio = true;
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

      final totalLength = toMerge.fold(0, (total, b) => total + b.length);
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

  /// Allows the user to barge in by tapping the screen during AI speech.
  Future<void> bargeIn() async {
    if (_currentState == LiveChatState.speaking) {
      debugPrint('[GeminiLive] User tapped to barge in');
      await _clearAudioQueue();
      _shouldSendAudio = true;
      _setState(LiveChatState.listening);
    }
  }

  void dispose() {
    stopSession();
    _stateController.close();
    _transcriptController.close();
    _audioLevelController.close();
    _activePatientController.close();
  }
}

class _AudioChunk {
  final Uint8List bytes;
  final String mimeType;
  final int? sampleRate;

  _AudioChunk(this.bytes, this.mimeType, {this.sampleRate});
}
