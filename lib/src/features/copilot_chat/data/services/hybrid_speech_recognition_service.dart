import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_speech_recognition_service.dart';
import 'native_speech_recognition_service.dart';
import 'speech_recognition_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';

/// Hybrid speech recognition service that intelligently routes between:
/// - Native speech recognition (speech_to_text) for Arabic and multilingual support
/// - Deepgram for English (higher quality, when working)
///
/// This allows us to:
/// 1. Support Arabic immediately using native recognition
/// 2. Keep Deepgram for English when it's working well
/// 3. Easy migration path if we decide to fully switch to native
class HybridSpeechRecognitionService
    implements AbstractSpeechRecognitionService {
  final NativeSpeechRecognitionService _nativeService;
  final SpeechRecognitionService _deepgramService;

  String _currentLanguage = 'en';
  AbstractSpeechRecognitionService? _activeService;

  HybridSpeechRecognitionService({
    required NativeSpeechRecognitionService nativeService,
    required SpeechRecognitionService deepgramService,
  }) : _nativeService = nativeService,
       _deepgramService = deepgramService;

  /// Determines which service to use based on current language and subscription
  Future<AbstractSpeechRecognitionService> _getServiceForLanguage() async {
    // 1. Always use native for non-English (Arabic, etc.) explicit support
    // (Optimization: don't check subscription if language forces native anyway)
    if (_currentLanguage == 'ar' ||
        _currentLanguage == 'fr' ||
        _currentLanguage == 'es' ||
        _currentLanguage == 'de') {
      debugPrint(
        '[HybridSpeech] Using native service for language: $_currentLanguage',
      );
      return _nativeService;
    }

    // 2. For English (or others), check if Deepgram is allowed by subscription
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String? clinicId;
        // Try getting clinic from OwnerNotifier if available (context-less via GetIt if registered? No, unsafe)
        // Fetch from Firestore directly
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        clinicId = userDoc.data()?['primaryClinicId'];

        if (clinicId != null) {
          final isDeepgramAllowed = await sl<SubscriptionService>()
              .isFeatureAllowed(clinicId, SubscriptionFeature.deepgram);

          if (!isDeepgramAllowed) {
            debugPrint(
              '[HybridSpeech] Deepgram not allowed by subscription. Using Native.',
            );
            return _nativeService;
          }
        }
      }
    } catch (e) {
      debugPrint(
        '[HybridSpeech] Error checking subscription: $e. Fallback to Native.',
      );
      return _nativeService; // Fail safe to native
    }

    // 3. Use Deepgram if allowed
    debugPrint(
      '[HybridSpeech] Using Deepgram service for language: $_currentLanguage',
    );
    return _deepgramService;
  }

  /// Set language and update both services
  void setLanguage(String languageCode) {
    _currentLanguage = languageCode;
    debugPrint('[HybridSpeech] Language changed to: $_currentLanguage');

    // Update both services
    _nativeService.setLanguage(languageCode);
    _deepgramService.setLanguage(languageCode);
  }

  @override
  Future<Either<Failure, bool>> initialize() async {
    debugPrint('[HybridSpeech] Initializing hybrid speech recognition...');

    // Initialize both services
    final nativeResult = await _nativeService.initialize();
    final deepgramResult = await _deepgramService.initialize();

    // Log results
    nativeResult.fold(
      (failure) => debugPrint(
        '[HybridSpeech] Native service init failed: ${failure.message}',
      ),
      (_) =>
          debugPrint('[HybridSpeech] Native service initialized successfully'),
    );

    deepgramResult.fold(
      (failure) => debugPrint(
        '[HybridSpeech] Deepgram service init failed: ${failure.message}',
      ),
      (_) => debugPrint(
        '[HybridSpeech] Deepgram service initialized successfully',
      ),
    );

    // Return success if at least one service is available
    if (nativeResult.isRight() || deepgramResult.isRight()) {
      return const Right(true);
    }

    // Both failed
    return Left(
      ServerFailure(
        'Both speech recognition services failed to initialize',
        500,
      ),
    );
  }

  @override
  Future<Either<Failure, bool>> startListening() async {
    _activeService = await _getServiceForLanguage();
    return _activeService!.startListening();
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    if (_activeService == null) {
      return Left(ServerFailure('No active service', 500));
    }
    return _activeService!.stopListening();
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    if (_activeService == null) {
      return const Right(true);
    }
    return _activeService!.cancelListening();
  }

  @override
  Future<void> dispose() async {
    await _nativeService.dispose();
    await _deepgramService.dispose();
  }

  @override
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable() async {
    return isAvailable();
  }

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    // Check if at least one service is available
    final nativeAvailable = await _nativeService.isAvailable();
    final deepgramAvailable = await _deepgramService.isAvailable();

    return Right(nativeAvailable.isRight() || deepgramAvailable.isRight());
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    // Return combined list of languages from both services
    final nativeResult = await _nativeService.getAvailableLanguages();
    final deepgramResult = await _deepgramService.getAvailableLanguages();

    final Set<String> allLanguages = {};

    nativeResult.fold((_) {}, (languages) => allLanguages.addAll(languages));

    deepgramResult.fold((_) {}, (languages) => allLanguages.addAll(languages));

    return Right(allLanguages.toList());
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    // Try native first, then Deepgram
    final nativeResult = await _nativeService.requestMicrophonePermission();
    if (nativeResult.isRight()) {
      return nativeResult;
    }
    return _deepgramService.requestMicrophonePermission();
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    // Check both services
    final nativeResult = await _nativeService.checkMicrophonePermission();
    if (nativeResult.isRight()) {
      return nativeResult;
    }
    return _deepgramService.checkMicrophonePermission();
  }

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    if (_activeService == null) {
      return Stream.value(Left(ServerFailure('No active service', 500)));
    }
    return _activeService!.getRealtimeRecognitionStream();
  }
}
