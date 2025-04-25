import 'package:dr_copilot/src/features/appointments/evaluations/evaluations_injections.dart';
import 'package:dr_copilot/src/features/appointments/sessions/sessions_injections.dart';
import 'package:dr_copilot/src/features/financials/financials_injections.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/core/network/network_info.dart';
import 'package:dr_copilot/src/features/patients/patients_injections.dart';
// Import other feature injection files as needed

final sl = GetIt.instance;

Future<void> initInjections() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Features
  initPatientsInjections();
  initEvaluationsInjections();
  initFinancialsInjections();
  initSessionsInjections();
  // Add more feature injection initializations here as your app grows
  

}
