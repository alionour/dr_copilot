import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/departments/data/repositories/departments_repository_impl.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';
import 'package:dr_copilot/src/features/departments/domain/usecases/departments_usecase.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_bloc.dart';

void initDepartmentsInjections() {
  sl.registerLazySingleton<AbstractDepartmentsRepository>(
    () => DepartmentsRepositoryImpl(),
  );

  sl.registerLazySingleton<DepartmentsUseCase>(
    () => DepartmentsUseCase(sl()),
  );

  sl.registerFactory<DepartmentsBloc>(
    () => DepartmentsBloc(departmentsUseCase: sl()),
  );
}
