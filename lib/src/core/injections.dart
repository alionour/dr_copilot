import 'package:dr_copilot/src/features/patients/patients_injections.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initInjections() async {
  initPatientsInjections();
}
