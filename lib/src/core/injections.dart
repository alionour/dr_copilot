import 'package:dr_copilot/src/features/patients/patients_injections.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/core/network/network_info.dart';

final sl = GetIt.instance;

Future<void> initInjections() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Features
  initPatientsInjections();
}
