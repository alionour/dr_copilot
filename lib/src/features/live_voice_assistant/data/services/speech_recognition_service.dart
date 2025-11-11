import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_speech_recognition_service.dart';
import 'dart:async';
import 'dart:developer';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class SpeechRecognitionService implements AbstractSpeechRecognitionService {
  final _audioRecorder = AudioRecorder();
  Deepgram? _deepgram;
  StreamSubscription? _deepgramSubscription;
  StreamController<String>? _recognitionController;

  final String _deepgramApiKey; // Placeholder for API key

  SpeechRecognitionService({required String deepgramApiKey})
      : _deepgramApiKey = deepgramApiKey;
  @override
  Future<Either<Failure, bool>> initialize() async {
    log('Deepgram API Key: $_deepgramApiKey');
    try {
      final hasRecorderPermission = await _audioRecorder.hasPermission();
      log('Audio recorder has permission: $hasRecorderPermission');

      if (hasRecorderPermission) {
        _deepgram = Deepgram(_deepgramApiKey);
        log('Deepgram initialized: ${_deepgram != null}');
        return const Right(true);
      } else {
        final permissionStatus = await Permission.microphone.request();
        log('Microphone permission request status: $permissionStatus');

        if (permissionStatus.isGranted) {
          _deepgram = Deepgram(_deepgramApiKey);
          log('Deepgram initialized after permission: ${_deepgram != null}');
          return const Right(true);
        } else {
          return Left(PermissionFailure('Microphone permission denied'));
        }
      }
    } catch (e) {
      log('Error during speech recognition initialization: ${e.toString()}');
      return Left(ServerFailure(
          'Failed to initialize speech recognition: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> startListening() async {
    try {
      if (_deepgram == null) {
        return Left(ServerFailure(
            'Deepgram not initialized. Call initialize() first.', 500));
      }

      if (await _audioRecorder.isRecording()) {
        return const Right(true); // Already listening
      }

      _recognitionController = StreamController<String>();

      // Start recording audio stream
      final audioStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _deepgramSubscription = _deepgram!.listen.live(
        audioStream,
        queryParams: {
          'language': 'en-US',
          'interim_results': true,
        },
      ).listen(
        (deepgramEvent) {
          if (deepgramEvent.isFinal) {
            _recognitionController?.add(deepgramEvent.transcript ?? '');
          }
        },
        onError: (error) {
          _recognitionController?.addError(error);
        },
        onDone: () {},
      );

      return const Right(true);
    } catch (e) {
      return Left(
          ServerFailure('Failed to start listening: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    try {
      if (!await _audioRecorder.isRecording()) {
        return const Right(''); // Not listening
      }

      await _deepgramSubscription?.cancel();
      _deepgramSubscription = null;

      final result = await _recognitionController?.stream
          .lastWhere((text) => text.isNotEmpty, orElse: () => '');
      await _recognitionController?.close();
      _recognitionController = null;

      return Right(result ?? '');
    } catch (e) {
      return Left(
          ServerFailure('Failed to stop listening: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }
      await _deepgramSubscription?.cancel();
      _deepgramSubscription = null;
      await _recognitionController?.close();
      _recognitionController = null;
      return const Right(true);
    } catch (e) {
      return Left(
          ServerFailure('Failed to cancel listening: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    try {
      final permissionGranted = await checkMicrophonePermission();
      log('Microphone permission granted (isAvailable): ${permissionGranted.isRight() ? permissionGranted.getOrElse(() => false) : false}');
      log('Deepgram object initialized (isAvailable): ${_deepgram != null}');

      return permissionGranted.fold(
        (l) => Left(l),
        (r) => Right(r && _deepgram != null),
      );
    } catch (e) {
      log('Error checking speech recognition availability: ${e.toString()}');
      return Left(ServerFailure(
          'Failed to check speech recognition availability: ${e.toString()}',
          500));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    try {
      // Deepgram supports many languages. For simplicity, returning a few common ones.
      return const Right(['en-US', 'es-ES', 'fr-FR', 'de-DE']);
    } catch (e) {
      return Left(ServerFailure(
          'Failed to get available languages: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
          'Failed to request microphone permission: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return Right(status.isGranted);
    } catch (e) {
      return Left(PermissionFailure(
          'Failed to check microphone permission: ${e.toString()}'));
    }
  }

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    return _recognitionController?.stream
            .map((text) => Right(text))
            .handleError((error) {
          if (error is Failure) {
            throw error;
          }
          throw ServerFailure(
              'Realtime recognition stream error: ${error.toString()}', 500);
        }).map((event) => event as Either<Failure, String>) ??
        Stream.value(
            Left(ServerFailure('Recognition stream not available.', 500)));
  }
}
