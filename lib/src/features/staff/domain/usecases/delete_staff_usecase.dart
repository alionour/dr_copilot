import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/core/usecase/usecase.dart';
import 'package:dr_copilot/src/features/staff/domain/repositories/staff_repository.dart';

class DeleteStaffUseCase implements UseCase<void, String> {
  final StaffRepository repository;

  DeleteStaffUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) {
    return repository.deleteStaff(params);
  }
}

