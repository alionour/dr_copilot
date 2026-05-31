import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'abstract_speech_recognition_service.dart';

/// Speech recognition service backed by **Google Cloud Speech-to-Text v1**
/// REST API, authenticated via a Service Account JSON file.
///
/// Auth: Loads `assets/google_credentials.json` and uses `googleapis_auth`
/// (`clientViaServiceAccount`) which is **already in this project's pubspec**
/// — zero new dependencies required.
///
/// Mode: Record audio to a temp file, then call the synchronous `recognize`
/// endpoint when the user stops. This pattern works on all platforms (mobile,
/// Windows, macOS) without gRPC.
///
/// Language support: All Google STT locales — English, Arabic, French, etc.
class GoogleSpeechRecognitionService implements AbstractSpeechRecognitionService {
  // ── state ────────────────────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();

  StreamController<String>? _recognitionController;
  Timer? _pulseTimer;

  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLanguage = 'en-US';

  // Cached authenticated HTTP client (auto-refreshes token)
  http.Client? _authClient;

  final StringBuffer _accumulatedTranscript = StringBuffer();

  // ── initialization ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> initialize() async {
    if (_isInitialized && _authClient != null) return const Right(true);

    try {
      // 1. Try Doppler env var first (FIREBASE_SERVICE_ACCOUNT)
      // 2. Fall back to bundled asset file
      final credJson = _loadCredentialsFromEnv() ??
          await _loadCredentialsFromAsset();

      if (credJson == null || credJson.trim().isEmpty) {
        debugPrint('[GoogleSpeech] No credentials found in env or asset file');
        return Left(ApiKeyFailure(
          'Google Cloud credentials not configured. '
          'Set FIREBASE_SERVICE_ACCOUNT in Doppler or fill in '
          'assets/google_credentials.json.',
        ));
      }

      final credMap = json.decode(credJson) as Map<String, dynamic>;

      final accountCredentials = ServiceAccountCredentials.fromJson(credMap);
      const scopes = ['https://www.googleapis.com/auth/cloud-platform'];

      // clientViaServiceAccount returns an AuthClient that auto-refreshes tokens
      _authClient = await clientViaServiceAccount(
        accountCredentials,
        scopes,
        baseClient: http.Client(),
      );

      _isInitialized = true;
      final source = _loadCredentialsFromEnv() != null ? 'Doppler env' : 'asset file';
      debugPrint('[GoogleSpeech] Initialized via $source — language: $_currentLanguage');
      return const Right(true);
    } on FormatException catch (e) {
      debugPrint('[GoogleSpeech] Bad credentials JSON: $e');
      return Left(ApiKeyFailure(
        'Invalid Service Account JSON: $e',
      ));
    } catch (e) {
      debugPrint('[GoogleSpeech] Initialization failed: $e');
      _isInitialized = false;
      _authClient?.close();
      _authClient = null;
      return Left(ServerFailure(
        'Failed to initialize Google Speech-to-Text: $e',
        500,
      ));
    }
  }

  /// Loads credentials from the FIREBASE_SERVICE_ACCOUNT environment variable.
  /// Doppler injects this at runtime via `doppler run -- flutter run`.
  String? _loadCredentialsFromEnv() {
    final value = Platform.environment['FIREBASE_SERVICE_ACCOUNT'];
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  /// Loads credentials from the bundled asset file as a fallback.
  Future<String?> _loadCredentialsFromAsset() async {
    try {
      final value =
          await rootBundle.loadString('assets/google_credentials.json');
      return value.trim().isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  // ── language ─────────────────────────────────────────────────────────────────

  void setLanguage(String languageCode) {
    _currentLanguage = _mapLocale(languageCode);
    debugPrint('[GoogleSpeech] Language → $_currentLanguage');
  }

  String _mapLocale(String code) {
    switch (code.toLowerCase()) {
      case 'ar':
        return 'ar-SA';
      case 'en':
        return 'en-US';
      case 'fr':
        return 'fr-FR';
      case 'es':
        return 'es-ES';
      case 'de':
        return 'de-DE';
      default:
        return 'en-US';
    }
  }

  // ── recording ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> startListening() async {
    if (_isListening) return const Right(true);

    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isLeft()) return initResult;
    }

    try {
      // Mic permission
      if (!await _recorder.hasPermission()) {
        final status = await Permission.microphone.request();
        if (!status.isGranted) {
          return Left(PermissionFailure('Microphone permission denied'));
        }
      }

      _accumulatedTranscript.clear();
      _recognitionController = StreamController<String>.broadcast();

      final tempPath = await _tempAudioPath();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
          autoGain: true,
        ),
        path: tempPath,
      );

      // Pulse timer — emits empty interim ticks so the UI stays responsive
      // (REST API has no real interim results)
      _pulseTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
        if (_isListening && !(_recognitionController?.isClosed ?? true)) {
          _recognitionController?.add(_accumulatedTranscript.toString());
        }
      });

      _isListening = true;
      debugPrint('[GoogleSpeech] Recording started → $_currentLanguage');
      return const Right(true);
    } catch (e) {
      debugPrint('[GoogleSpeech] startListening error: $e');
      return Left(
        ServerFailure('Failed to start Google speech recognition: $e', 500),
      );
    }
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    if (!_isListening) {
      final result = _buildFinalResult();
      _cleanupState();
      return Right(result);
    }

    try {
      debugPrint('[GoogleSpeech] Stopping...');
      _pulseTimer?.cancel();
      _pulseTimer = null;

      final path = await _recorder.stop();
      _isListening = false;

      if (path == null || path.isEmpty) {
        await _closeController();
        _cleanupState();
        return Left(ServerFailure('No audio file recorded', 500));
      }

      // Send to Google Speech-to-Text
      final transcriptResult = await _recognizeAudioFile(path);

      // Push final result to stream before closing
      transcriptResult.fold(
        (_) {},
        (t) => _recognitionController?.add(t),
      );

      await _closeController();
      _cleanupState();
      return transcriptResult;
    } catch (e) {
      debugPrint('[GoogleSpeech] stopListening error: $e');
      _isListening = false;
      await _closeController();
      _cleanupState();
      return Left(
        ServerFailure('Failed to stop Google speech recognition: $e', 500),
      );
    }
  }

  Future<Either<Failure, String>> _recognizeAudioFile(String filePath) async {
    try {
      final client = _authClient;
      if (client == null) {
        return Left(ServerFailure('Auth client not initialized', 500));
      }

      // Read audio bytes
      final audioBytes = await File(filePath).readAsBytes();
      if (audioBytes.isEmpty) {
        debugPrint('[GoogleSpeech] Audio file is empty');
        return Right('__FINAL__:');
      }

      final audioBase64 = base64.encode(audioBytes);
      debugPrint('[GoogleSpeech] Sending ${audioBytes.length} bytes to Google STT');

      final requestBody = json.encode({
        'config': {
          'encoding': 'LINEAR16',
          'sampleRateHertz': 16000,
          'languageCode': _currentLanguage,
          'enableAutomaticPunctuation': true,
          'model': 'latest_long',
          'useEnhanced': true,
        },
        'audio': {
          'content': audioBase64,
        },
      });

      final response = await client
          .post(
            Uri.parse(
              'https://speech.googleapis.com/v1/speech:recognize',
            ),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      // Clean up temp file
      try {
        await File(filePath).delete();
      } catch (_) {}

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final results = (body['results'] as List<dynamic>?) ?? [];

        if (results.isEmpty) {
          debugPrint('[GoogleSpeech] No speech detected');
          return Right('__FINAL__:');
        }

        final transcript = results
            .map((r) =>
                ((r['alternatives'] as List<dynamic>).first['transcript']
                    as String)
                    .trim())
            .where((t) => t.isNotEmpty)
            .join(' ')
            .trim();

        debugPrint('[GoogleSpeech] Transcript: "$transcript"');
        return Right('__FINAL__:$transcript');
      } else {
        debugPrint(
          '[GoogleSpeech] API error ${response.statusCode}: ${response.body}',
        );
        return Left(ServerFailure(
          'Google Speech API error: ${response.statusCode}',
          response.statusCode,
        ));
      }
    } on TimeoutException {
      return Left(
        ServerFailure('Google Speech API request timed out', 504),
      );
    } catch (e) {
      debugPrint('[GoogleSpeech] Transcription error: $e');
      return Left(ServerFailure('Transcription failed: $e', 500));
    }
  }

  // ── cancel ────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    try {
      _pulseTimer?.cancel();
      _pulseTimer = null;
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
      _isListening = false;
      await _closeController();
      _cleanupState();
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to cancel: $e', 500));
    }
  }

  // ── availability ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable() => isAvailable();

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    final perm = await checkMicrophonePermission();
    return perm.fold(Left.new, (granted) => Right(granted && _isInitialized));
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    return const Right([
      'en-US', 'en-GB',
      'ar-SA', 'ar-EG',
      'fr-FR',
      'es-ES',
      'de-DE',
    ]);
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure('Failed to request mic permission: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure('Failed to check mic permission: $e'));
    }
  }

  // ── stream ────────────────────────────────────────────────────────────────────

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    if (_recognitionController == null || _recognitionController!.isClosed) {
      return Stream.value(
        Left(ServerFailure('Recognition stream not active.', 500)),
      );
    }
    return _recognitionController!.stream
        .map<Either<Failure, String>>((t) => Right(t))
        .handleError(
          (dynamic e) => Left(ServerFailure('$e', 500)),
        );
  }

  @override
  void clearAccumulatedTranscript() {
    _accumulatedTranscript.clear();
    debugPrint('[GoogleSpeech] Cleared accumulated transcript');
  }

  // ── dispose ───────────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    _pulseTimer?.cancel();
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
    _recorder.dispose();
    await _closeController();
    _authClient?.close();
    _authClient = null;
    _isInitialized = false;
    _isListening = false;
  }

  // ── helpers ───────────────────────────────────────────────────────────────────

  String _buildFinalResult() {
    final acc = _accumulatedTranscript.toString().trim();
    return acc.isNotEmpty ? '__FINAL__:$acc' : '__FINAL__:';
  }

  void _cleanupState() {
    _accumulatedTranscript.clear();
  }

  Future<void> _closeController() async {
    if (_recognitionController != null && !_recognitionController!.isClosed) {
      await _recognitionController!.close();
    }
    _recognitionController = null;
  }

  Future<String> _tempAudioPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/google_stt_${DateTime.now().millisecondsSinceEpoch}.wav';
  }
}
