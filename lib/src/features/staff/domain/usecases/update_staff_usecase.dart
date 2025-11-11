import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/core/usecase/usecase.dart';
import 'package:dr_copilot/src/features/staff/domain/entities/staff.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';
import 'package:dr_copilot/src/features/staff/domain/repositories/staff_repository.dart';

class UpdateStaffUseCase implements UseCase<void, Staff> {
  final StaffRepository repository;

  UpdateStaffUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(Staff params) {
    final staffModel = StaffModel(
      id: params.id,
      name: params.name,
      email: params.email,
      phoneNumber: params.phoneNumber,
      role: params.role,
      clinicId: params.clinicId,
      createdAt: params.createdAt,
      updatedAt: params.updatedAt,
    );
    return repository.updateStaff(params.id, staffModel);
  }
}
