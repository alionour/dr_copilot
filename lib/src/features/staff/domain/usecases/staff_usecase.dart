import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';
import 'package:dr_copilot/src/features/staff/domain/repositories/staff_repository.dart';

class StaffUseCases {
  final StaffRepository _repository;

  StaffUseCases(this._repository);

  Future<Either<Failure, List<StaffModel>>> getAllStaff({required String clinicId}) {
    return _repository.getAllStaff(clinicId: clinicId);
  }

  Future<Either<Failure, void>> addStaff(StaffModel staff) {
    return _repository.addStaff(staff);
  }

  Future<Either<Failure, void>> updateStaff(String staffId, StaffModel staff) {
    return _repository.updateStaff(staffId, staff);
  }

  Future<Either<Failure, void>> deleteStaff(String staffId) {
    return _repository.deleteStaff(staffId);
  }
}