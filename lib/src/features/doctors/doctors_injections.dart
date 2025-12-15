import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/doctors/data/remote/doctor_firebase_api.dart';
import 'package:dr_copilot/src/features/doctors/data/repositories/doctor_repository_impl.dart';
import 'package:dr_copilot/src/features/doctors/domain/repositories/doctor_repository.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';

void initDoctorsInjections() {
  // Bloc
  sl.registerFactory(() => DoctorsBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => DoctorsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<DoctorRepository>(() => DoctorRepositoryImpl(sl()));

  // Data sources
  sl.registerLazySingleton(() => DoctorFirebaseApi());
}

