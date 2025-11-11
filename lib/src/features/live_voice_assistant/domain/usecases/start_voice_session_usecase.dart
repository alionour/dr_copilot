import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import '../models/voice_session_model.dart';
import '../repositories/abstract_live_assistant_repository.dart';

/// Use case for starting a new voice session
class StartVoiceSessionUseCase {
  final AbstractLiveAssistantRepository repository;

  StartVoiceSessionUseCase(this.repository);

  /// Start a new voice session
  Future<Either<Failure, VoiceSessionModel>> call({
    required String userId,
    String? title,
    String? selectedAiModel,
  }) async {
    try {
      // Check microphone permission first
      final permissionResult = await repository.checkMicrophonePermission();
      if (permissionResult.isLeft()) {
        return Left(permissionResult.fold(
            (l) => l, (r) => ServerFailure('Permission check failed', 403)));
      }

      final hasPermission = permissionResult.fold((l) => false, (r) => r);
      if (!hasPermission) {
        final requestResult = await repository.requestMicrophonePermission();
        if (requestResult.isLeft()) {
          return Left(requestResult.fold((l) => l,
              (r) => ServerFailure('Permission request failed', 403)));
        }

        final granted = requestResult.fold((l) => false, (r) => r);
        if (!granted) {
          return Left(ServerFailure('Microphone permission denied', 403));
        }
      }

      // Initialize speech recognition
      final speechInitResult = await repository.initializeSpeechRecognition();
      if (speechInitResult.isLeft()) {
        return Left(speechInitResult.fold(
            (l) => l,
            (r) => ServerFailure(
                'Speech recognition initialization failed', 500)));
      }

      // Initialize text-to-speech
      final ttsInitResult = await repository.initializeTextToSpeech();
      if (ttsInitResult.isLeft()) {
        return Left(ttsInitResult.fold((l) => l,
            (r) => ServerFailure('Text-to-speech initialization failed', 500)));
      }

      // Create the voice session
      final sessionResult = await repository.createVoiceSession(
        userId: userId,
        title: title,
        selectedAiModel: selectedAiModel ?? 'Gemini',
      );

      return sessionResult;
    } catch (e) {
      return Left(
          ServerFailure('Failed to start voice session: ${e.toString()}', 500));
    }
  }

  /// Check if voice session can be started
  Future<Either<Failure, bool>> canStartVoiceSession() async {
    try {
      // Check if speech recognition is available
      final speechAvailableResult =
          await repository.isSpeechRecognitionAvailable();
      if (speechAvailableResult.isLeft()) {
        return Left(speechAvailableResult.fold(
            (l) => l, (r) => ServerFailure('Speech check failed', 500)));
      }

      final speechAvailable =
          speechAvailableResult.fold((l) => false, (r) => r);
      if (!speechAvailable) {
        return Left(ServerFailure(
            'Speech recognition not available on this device', 404));
      }

      // Check microphone permission
      final permissionResult = await repository.checkMicrophonePermission();
      if (permissionResult.isLeft()) {
        return Left(permissionResult.fold(
            (l) => l, (r) => ServerFailure('Permission check failed', 403)));
      }

      return Right(true);
    } catch (e) {
      return Left(ServerFailure(
          'Failed to check voice session availability: ${e.toString()}', 500));
    }
  }

  /// Get available languages for speech recognition
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    return await repository.getAvailableLanguages();
  }

  /// Get available voices for text-to-speech
  Future<Either<Failure, List<String>>> getAvailableVoices() async {
    return await repository.getAvailableVoices();
  }
}
