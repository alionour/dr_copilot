import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initPatientsInjections() {
  // Bloc
  sl.registerFactory(() => PatientsBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => PatientsUseCase(sl()));

  // Repository (register as abstract type)
  sl.registerLazySingleton<AbstractPatientsRepository>(
    () => PatientsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<PatientFirebaseApi>(
    () => PatientFirebaseApi(),
  );
}
