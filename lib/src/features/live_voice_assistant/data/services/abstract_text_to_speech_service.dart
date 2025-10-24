import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';

abstract class AbstractTextToSpeechService {
  Future<Either<Failure, bool>> initialize();
  Future<Either<Failure, bool>> speak(String text);
  Future<Either<Failure, bool>> stopSpeaking();
  Future<Either<Failure, bool>> pauseSpeaking();
  Future<Either<Failure, bool>> resumeSpeaking();
  Future<Either<Failure, bool>> isSpeaking();
  Future<Either<Failure, List<String>>> getAvailableVoices();
  Future<Either<Failure, bool>> setVoice(String voiceId);
  Future<Either<Failure, bool>> setSpeechRate(double rate);
  Future<Either<Failure, bool>> setPitch(double pitch);
}
