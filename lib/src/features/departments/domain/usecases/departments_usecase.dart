import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';

class DepartmentsUseCase {
  final AbstractDepartmentsRepository repository;

  DepartmentsUseCase(this.repository);

  Future<Either<Failure, List<DepartmentModel>>> getDepartments(String clinicId) {
    return repository.getDepartments(clinicId);
  }

  Future<Either<Failure, DepartmentModel>> addDepartment(DepartmentModel department) {
    return repository.addDepartment(department);
  }

  Future<Either<Failure, void>> deleteDepartment(String id, String clinicId) {
    return repository.deleteDepartment(id, clinicId);
  }
}
