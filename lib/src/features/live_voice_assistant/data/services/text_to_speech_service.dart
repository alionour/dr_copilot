import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_text_to_speech_service.dart';

class TextToSpeechService implements AbstractTextToSpeechService {
  bool _isSpeaking = false;

  @override
  Future<Either<Failure, bool>> initialize() async {
    log('TextToSpeechService: initialize (dummy implementation)');
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> speak(String text) async {
    log('TextToSpeechService: speak "$text" (dummy implementation)');
    _isSpeaking = true;
    // Simulate speaking time
    await Future.delayed(Duration(seconds: (text.length / 10).ceil()));
    _isSpeaking = false;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> stopSpeaking() async {
    log('TextToSpeechService: stopSpeaking (dummy implementation)');
    _isSpeaking = false;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> pauseSpeaking() async {
    log('TextToSpeechService: pauseSpeaking (dummy implementation)');
    _isSpeaking = false;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> resumeSpeaking() async {
    log('TextToSpeechService: resumeSpeaking (dummy implementation)');
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> isSpeaking() async {
    log('TextToSpeechService: isSpeaking (dummy implementation)');
    return Right(_isSpeaking);
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableVoices() async {
    log('TextToSpeechService: getAvailableVoices (dummy implementation)');
    return const Right(['Dummy Voice 1', 'Dummy Voice 2']);
  }

  @override
  Future<Either<Failure, bool>> setVoice(String voiceId) async {
    log('TextToSpeechService: setVoice "$voiceId" (dummy implementation)');
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> setSpeechRate(double rate) async {
    log('TextToSpeechService: setSpeechRate "$rate" (dummy implementation)');
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> setPitch(double pitch) async {
    log('TextToSpeechService: setPitch "$pitch" (dummy implementation)');
    return const Right(true);
  }
}