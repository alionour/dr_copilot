
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_text_to_speech_service.dart';

class TextToSpeechService implements AbstractTextToSpeechService {
  @override
  Future<Either<Failure, bool>> initialize() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> speak(String text) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> stopSpeaking() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> pauseSpeaking() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> resumeSpeaking() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> isSpeaking() async {
    return const Right(false);
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableVoices() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, bool>> setVoice(String voiceId) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> setSpeechRate(double rate) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> setPitch(double pitch) async {
    return const Right(true);
  }
}
