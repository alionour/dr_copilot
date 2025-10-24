
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_speech_recognition_service.dart';

class SpeechRecognitionService implements AbstractSpeechRecognitionService {
  @override
  Future<Either<Failure, bool>> initialize() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> startListening() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    return const Right("");
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> isAvailable() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    return const Right(true);
  }

  @override
  Stream<Either<Failure, String>> getRealtimeRecognitionStream() {
    return Stream.value(const Right(""));
  }
}
