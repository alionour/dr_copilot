import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';

abstract class DepartmentsEvent extends Equatable {
  const DepartmentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDepartmentsEvent extends DepartmentsEvent {
  final String clinicId;
  const LoadDepartmentsEvent(this.clinicId);

  @override
  List<Object?> get props => [clinicId];
}

class AddDepartmentEvent extends DepartmentsEvent {
  final DepartmentModel department;
  const AddDepartmentEvent(this.department);

  @override
  List<Object?> get props => [department];
}

class DeleteDepartmentEvent extends DepartmentsEvent {
  final String id;
  final String clinicId;
  const DeleteDepartmentEvent(this.id, this.clinicId);

  @override
  List<Object?> get props => [id, clinicId];
}
