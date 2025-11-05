
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/core/usecase/usecase.dart';
import 'package:dr_copilot/src/features/staff/domain/repositories/staff_repository.dart';
import 'package:dr_copilot/src/features/staff/domain/entities/staff.dart';

class GetStaffUseCase implements UseCase<List<Staff>, NoParams> {
  final StaffRepository repository;

  GetStaffUseCase(this.repository);

  @override
  Future<Either<Failure, List<Staff>>> call(NoParams params) async {
    return await repository.getAllStaff();
  }
}
