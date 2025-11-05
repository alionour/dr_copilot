import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';

abstract class StaffRepository {
  Future<Either<Failure, List<StaffModel>>> getAllStaff();
  Future<Either<Failure, void>> addStaff(StaffModel staff);
  Future<Either<Failure, void>> updateStaff(String staffId, StaffModel staff);
  Future<Either<Failure, void>> deleteStaff(String staffId);
}