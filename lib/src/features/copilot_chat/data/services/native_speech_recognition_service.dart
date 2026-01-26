import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'abstract_speech_recognition_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Native speech recognition service using device's built-in speech recognition
/// Supports 100+ languages including Arabic
class NativeSpeechRecognitionService
    implements AbstractSpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _lastTranscript = '';
  String _currentLanguage = 'en_US';

  StreamController<String>? _recognitionController;
  Completer<String>? _finalTranscriptCompleter;

  @override
  Future<Either<Failure, bool>> initialize() async {
    if (_isInitialized) {
      debugPrint('[NativeSpeech] Already initialized');
      return const Right(true);
    }

    try {
      debugPrint('[NativeSpeech] Initializing native speech recognition...');

      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[NativeSpeech] Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          debugPrint('[NativeSpeech] Error: ${error.errorMsg}');
        },
      );

      if (_isInitialized) {
        // Log available locales
        final locales = await _speech.locales();
        debugPrint('[NativeSpeech] Available locales: ${locales.length}');
        debugPrint(
          '[NativeSpeech] All locales: ${locales.map((l) => l.localeId).join(", ")}',
        );
        final arabicLocales =
            locales.where((l) => l.localeId.startsWith('ar')).toList();
        debugPrint(
          '[NativeSpeech] Arabic locales found: ${arabicLocales.length}',
        );
        if (arabicLocales.isNotEmpty) {
          debugPrint(
            '[NativeSpeech] Arabic locales: ${arabicLocales.map((l) => l.localeId).join(", ")}',
          );
        } else {
          debugPrint(
            '[NativeSpeech] WARNING: No Arabic locales found! Arabic speech recognition may not work.',
          );
          debugPrint(
            '[NativeSpeech] To fix: Add Arabic language in device Settings → Languages',
          );
        }
        return const Right(true);
      } else {
        debugPrint(
          '[NativeSpeech] ERROR: Speech recognition initialization failed!',
        );
        return Left(
          ServerFailure('Speech recognition not available on this device', 500),
        );
      }
    } catch (e) {
      debugPrint('[NativeSpeech] Initialization failed: $e');
      return Left(
        ServerFailure(
          'Failed to initialize native speech recognition: ${e.toString()}',
          500,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> startListening() async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isLeft()) {
        return initResult;
      }
    }

    if (_isListening) {
      debugPrint('[NativeSpeech] Already listening');
      return const Right(true);
    }

    try {
      _lastTranscript = '';
      _recognitionController = StreamController<String>.broadcast();
      _finalTranscriptCompleter = Completer<String>();

      // Verify the locale is available on the device
      final locales = await _speech.locales();

      if (locales.isEmpty) {
        debugPrint(
          '[NativeSpeech] ERROR: No locales available on this device!',
        );
        return Left(
          ServerFailure(
            'No speech recognition locales available on this device',
            500,
          ),
        );
      }

      debugPrint(
        '[NativeSpeech] Available locales for selection: ${locales.map((l) => l.localeId).take(5).join(", ")}...',
      );

      final requestedLocale = locales.firstWhere(
        (l) => l.localeId == _currentLanguage,
        orElse: () {
          // Try to find any locale that matches the language code
          final languageCode = _currentLanguage.split('_')[0];
          final matchingLocale = locales.firstWhere(
            (l) => l.localeId.startsWith(languageCode),
            orElse: () {
              debugPrint(
                '[NativeSpeech] WARNING: No locale found for $languageCode, using first available: ${locales.first.localeId}',
              );
              return locales.first;
            },
          );
          debugPrint(
            '[NativeSpeech] Requested locale $_currentLanguage not found, using ${matchingLocale.localeId}',
          );
          return matchingLocale;
        },
      );

      final actualLocaleId = requestedLocale.localeId;
      debugPrint(
        '[NativeSpeech] Starting to listen with language: $actualLocaleId (requested: $_currentLanguage)',
      );

      await _speech.listen(
        onResult: (result) {
          debugPrint(
            '[NativeSpeech] Result: "${result.recognizedWords}" (final: ${result.finalResult})',
          );
          _lastTranscript = result.recognizedWords;
          _recognitionController?.add(result.recognizedWords);

          if (result.finalResult) {
            final formattedFinal = '__FINAL__:${result.recognizedWords}';
            _recognitionController?.add(formattedFinal);

            if (_finalTranscriptCompleter != null &&
                !_finalTranscriptCompleter!.isCompleted) {
              _finalTranscriptCompleter!.complete(result.recognizedWords);
            }
          } else {
            _recognitionController?.add(result.recognizedWords);
          }
        },
        localeId: actualLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          onDevice:
              false, // Use cloud-based recognition for better Arabic support
        ),
      );

      _isListening = true;
      debugPrint('[NativeSpeech] Listening started successfully');
      return const Right(true);
    } catch (e) {
      debugPrint('[NativeSpeech] Failed to start listening: $e');
      return Left(
        ServerFailure('Failed to start listening: ${e.toString()}', 500),
      );
    }
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    try {
      debugPrint('[NativeSpeech] Stopping listening...');

      if (!_isListening) {
        debugPrint(
          '[NativeSpeech] Not listening, returning current transcript: "$_lastTranscript"',
        );
        return Right(_lastTranscript);
      }

      // Stop the speech recognition
      await _speech.stop();
      _isListening = false;

      // Wait for final result with timeout
      String finalTranscript;
      try {
        finalTranscript = await _finalTranscriptCompleter!.future.timeout(
          const Duration(milliseconds: 1000),
          onTimeout: () {
            debugPrint(
              '[NativeSpeech] Timeout waiting for final result, using _lastTranscript',
            );
            return _lastTranscript;
          },
        );
      } catch (e) {
        debugPrint(
          '[NativeSpeech] Error waiting for final result: $e, using _lastTranscript',
        );
        finalTranscript = _lastTranscript;
      }

      // Cleanup
      await _recognitionController?.close();
      _recognitionController = null;
      _finalTranscriptCompleter = null;

      debugPrint(
        '[NativeSpeech] Stopped listening, final transcript: "$finalTranscript" (length: ${finalTranscript.length})',
      );

      // Reset for next session
      final result = finalTranscript;
      _lastTranscript = '';

      if (result.isEmpty) {
        debugPrint(
          '[NativeSpeech] WARNING: No speech was recognized. Check if microphone permissions are granted and device supports the selected language.',
        );
      }

      return Right(result);
    } catch (e) {
      debugPrint('[NativeSpeech] Error stopping listening: $e');
      _isListening = false;
      return Left(
        ServerFailure('Failed to stop listening: ${e.toString()}', 500),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    try {
      await _speech.cancel();
      _isListening = false;
      await _recognitionController?.close();
      _recognitionController = null;
      _finalTranscriptCompleter = null;
      _lastTranscript = '';
      return const Right(true);
    } catch (e) {
      return Left(
        ServerFailure('Failed to cancel listening: ${e.toString()}', 500),
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _speech.stop();
      await _recognitionController?.close();
      _isInitialized = false;
      _isListening = false;
    } catch (e) {
      debugPrint('[NativeSpeech] Error during dispose: $e');
    }
  }

  @override
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable() async {
    return isAvailable();
  }

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    try {
      if (!_isInitialized) {
        final initResult = await initialize();
        return initResult;
      }
      return Right(_isInitialized);
    } catch (e) {
      return Left(
        ServerFailure('Failed to check availability: ${e.toString()}', 500),
      );
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final locales = await _speech.locales();
      final languageCodes = locales.map((locale) => locale.localeId).toList();
      return Right(languageCodes);
    } catch (e) {
      return Left(
        ServerFailure(
          'Failed to get available languages: ${e.toString()}',
          500,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    // Permission is handled by speech_to_text.initialize()
    return initialize();
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    return Right(_isInitialized);
  }

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    if (_recognitionController == null) {
      return Stream.value(
        Left(ServerFailure('Recognition stream not available.', 500)),
      );
    }

    return _recognitionController!.stream
        .map<Either<Failure, String>>((text) => Right(text))
        .handleError((error) {
      return Left(
        ServerFailure(
          'Realtime recognition stream error: ${error.toString()}',
          500,
        ),
      );
    });
  }

  /// Set the language for speech recognition
  void setLanguage(String languageCode) {
    // Map Flutter locale codes to speech_to_text locale IDs
    // We store the preferred locale, but will check availability at listen time
    switch (languageCode) {
      case 'ar':
        // Try common Arabic locales in order of preference
        // ar_SA (Saudi Arabia), ar_EG (Egypt), ar_AE (UAE), ar_JO (Jordan)
        _currentLanguage = 'ar_SA';
        break;
      case 'en':
        _currentLanguage = 'en_US';
        break;
      case 'fr':
        _currentLanguage = 'fr_FR';
        break;
      case 'es':
        _currentLanguage = 'es_ES';
        break;
      case 'de':
        _currentLanguage = 'de_DE';
        break;
      default:
        _currentLanguage = 'en_US';
    }

    debugPrint(
      '[NativeSpeech] Language preference set to: $_currentLanguage (from code: $languageCode)',
    );
  }

  @override
  void clearAccumulatedTranscript() {
    _lastTranscript = '';
    debugPrint('[NativeSpeech] Cleared accumulated transcript');
  }
}
