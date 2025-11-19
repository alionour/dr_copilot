import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';

abstract class AbstractSpeechRecognitionService {
  Future<Either<Failure, bool>> initialize();
  Future<Either<Failure, bool>> startListening();
  Future<Either<Failure, String>> stopListening();
  Future<Either<Failure, bool>> cancelListening();
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable();
  Future<Either<Failure, bool>> isAvailable();
  Future<Either<Failure, List<String>>> getAvailableLanguages();
  Future<Either<Failure, bool>> requestMicrophonePermission();
  Future<Either<Failure, bool>> checkMicrophonePermission();
  Stream<Either<Failure, String>> getRealtimeRecognitionStream();
  Future<void> dispose();
}