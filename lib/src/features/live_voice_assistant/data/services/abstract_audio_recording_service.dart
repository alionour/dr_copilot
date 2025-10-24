import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';

abstract class AbstractAudioRecordingService {
  Future<Either<Failure, bool>> deleteRecordingFile(String filePath);
}
