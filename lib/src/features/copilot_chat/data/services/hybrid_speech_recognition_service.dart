import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_speech_recognition_service.dart';
import 'google_speech_recognition_service.dart';
import 'native_speech_recognition_service.dart';
import 'package:flutter/foundation.dart';

/// Hybrid speech recognition service that routes between:
/// - **Google Cloud STT** (primary — all languages, English + Arabic + others)
/// - **NativeSpeechRecognitionService** (fallback — when Google credentials are
///   missing or an API error occurs)
///
/// Both services are singletons injected via GetIt.
class HybridSpeechRecognitionService implements AbstractSpeechRecognitionService {
  final GoogleSpeechRecognitionService _googleService;
  final NativeSpeechRecognitionService _nativeService;

  String _currentLanguage = 'en';
  AbstractSpeechRecognitionService? _activeService;
  bool _googleAvailable = false;

  HybridSpeechRecognitionService({
    required GoogleSpeechRecognitionService googleService,
    required NativeSpeechRecognitionService nativeService,
  })  : _googleService = googleService,
        _nativeService = nativeService;

  // ── language ─────────────────────────────────────────────────────────────────

  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    debugPrint('[HybridSpeech] Language → $_currentLanguage');
    _googleService.setLanguage(languageCode);
    _nativeService.setLanguage(languageCode);
  }

  // ── initialization ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> initialize() async {
    debugPrint('[HybridSpeech] Initializing...');

    // Try Google STT first
    final googleResult = await _googleService.initialize();
    googleResult.fold(
      (failure) {
        debugPrint('[HybridSpeech] Google STT init failed: ${failure.message}');
        _googleAvailable = false;
      },
      (_) {
        debugPrint('[HybridSpeech] Google STT initialized');
        _googleAvailable = true;
      },
    );

    // Always initialize native as backup
    final nativeResult = await _nativeService.initialize();
    nativeResult.fold(
      (failure) => debugPrint(
        '[HybridSpeech] Native STT init failed: ${failure.message}',
      ),
      (_) => debugPrint('[HybridSpeech] Native STT initialized'),
    );

    // Success if at least one service is available
    if (_googleAvailable || nativeResult.isRight()) {
      return const Right(true);
    }

    return Left(
      ServerFailure('All speech recognition services failed to initialize', 500),
    );
  }

  // ── routing ───────────────────────────────────────────────────────────────────

  /// Returns Google STT if available, otherwise falls back to native.
  AbstractSpeechRecognitionService _selectService() {
    if (_googleAvailable) {
      debugPrint('[HybridSpeech] Using Google STT — language: $_currentLanguage');
      return _googleService;
    }
    debugPrint('[HybridSpeech] Falling back to Native STT');
    return _nativeService;
  }

  // ── listening ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> startListening() async {
    _activeService = _selectService();

    final result = await _activeService!.startListening();

    // If Google fails at start time, try native as fallback
    if (result.isLeft() && _activeService is GoogleSpeechRecognitionService) {
      debugPrint('[HybridSpeech] Google STT start failed — falling back to native');
      _googleAvailable = false;
      _activeService = _nativeService;
      return _activeService!.startListening();
    }

    return result;
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    if (_activeService == null) {
      return Left(ServerFailure('No active STT service', 500));
    }
    return _activeService!.stopListening();
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    if (_activeService == null) return const Right(true);
    return _activeService!.cancelListening();
  }

  // ── availability ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable() => isAvailable();

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    final googleAvail = await _googleService.isAvailable();
    if (googleAvail.isRight()) return googleAvail;
    return _nativeService.isAvailable();
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    final googleResult = await _googleService.getAvailableLanguages();
    final nativeResult = await _nativeService.getAvailableLanguages();

    final Set<String> all = {};
    googleResult.fold((_) {}, all.addAll);
    nativeResult.fold((_) {}, all.addAll);

    return Right(all.toList());
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    // Delegate to Google service (which uses permission_handler — same as native)
    final result = await _googleService.requestMicrophonePermission();
    if (result.isRight()) return result;
    return _nativeService.requestMicrophonePermission();
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    return _googleService.checkMicrophonePermission();
  }

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    if (_activeService == null) {
      return Stream.value(Left(ServerFailure('No active STT service', 500)));
    }
    return _activeService!.getRealtimeRecognitionStream();
  }

  @override
  void clearAccumulatedTranscript() {
    _googleService.clearAccumulatedTranscript();
    _nativeService.clearAccumulatedTranscript();
  }

  @override
  Future<void> dispose() async {
    await _googleService.dispose();
    await _nativeService.dispose();
  }
}
