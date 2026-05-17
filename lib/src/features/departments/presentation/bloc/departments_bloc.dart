import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/departments/domain/usecases/departments_usecase.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_event.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_state.dart';

class DepartmentsBloc extends Bloc<DepartmentsEvent, DepartmentsState> {
  final DepartmentsUseCase departmentsUseCase;

  DepartmentsBloc({required this.departmentsUseCase}) : super(DepartmentsInitial()) {
    on<LoadDepartmentsEvent>((event, emit) async {
      emit(DepartmentsLoading());
      final result = await departmentsUseCase.getDepartments(event.clinicId);
      result.fold(
        (failure) => emit(DepartmentsError(failure.message)),
        (departments) => emit(DepartmentsLoaded(departments)),
      );
    });

    on<AddDepartmentEvent>((event, emit) async {
      final result = await departmentsUseCase.addDepartment(event.department);
      result.fold(
        (failure) => emit(DepartmentsError(failure.message)),
        (department) => emit(const DepartmentOperationSuccess('Department added successfully')),
      );
    });

    on<DeleteDepartmentEvent>((event, emit) async {
      final result = await departmentsUseCase.deleteDepartment(event.id, event.clinicId);
      result.fold(
        (failure) => emit(DepartmentsError(failure.message)),
        (_) => emit(const DepartmentOperationSuccess('Department deleted successfully')),
      );
    });
  }
}
