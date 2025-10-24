
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'abstract_audio_recording_service.dart';

class AudioRecordingService implements AbstractAudioRecordingService {
  @override
  Future<Either<Failure, bool>> deleteRecordingFile(String filePath) async {
    return const Right(true);
  }
}
