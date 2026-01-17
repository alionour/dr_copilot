import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/analytics_model.dart';

abstract class ChartsRepository {
  Future<Either<Failure, AnalyticsData>> getAnalyticsData(String clinicId);
}
