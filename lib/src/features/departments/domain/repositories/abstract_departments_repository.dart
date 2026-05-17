import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';

abstract class AbstractDepartmentsRepository {
  Future<Either<Failure, List<DepartmentModel>>> getDepartments(String clinicId);
  Future<Either<Failure, DepartmentModel>> addDepartment(DepartmentModel department);
  Future<Either<Failure, void>> deleteDepartment(String id, String clinicId);
}
