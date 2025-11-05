import 'package:dr_copilot/src/features/staff/data/remote/staff_firebase_api.dart';
import 'package:dr_copilot/src/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:dr_copilot/src/features/staff/domain/repositories/staff_repository.dart';
import 'package:dr_copilot/src/features/staff/domain/usecases/staff_usecase.dart';
import 'package:dr_copilot/src/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initStaffInjections() {
  // Blocs
  sl.registerFactory(() => StaffBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => StaffUseCases(sl()));

  // Repositories
  sl.registerLazySingleton<StaffRepository>(() => StaffRepositoryImpl(sl()));

  // APIs
  sl.registerLazySingleton(() => StaffFirebaseApi());
}
