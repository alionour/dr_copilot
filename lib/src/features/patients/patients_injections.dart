import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_impl_api.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';

final sl = GetIt.instance;

void initPatientsInjections() {
  // Register API
  sl.registerLazySingleton<PatientImplApi>(() => PatientImplApi('https://api.example.com'));

  // Register Repository
  sl.registerLazySingleton<AbstractPatientsRepository>(() => PatientsRepositoryImpl(sl()));

  // Register UseCase
  sl.registerLazySingleton<PatientsUseCase>(() => PatientsUseCase(sl()));
}
