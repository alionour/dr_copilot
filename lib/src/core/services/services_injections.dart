import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/core/services/google_drive_service.dart';
import 'package:dr_copilot/src/core/services/fcm_service.dart';
import 'package:dr_copilot/src/core/services/feature_discovery_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

void initServicesInjections() {
  sl.registerLazySingleton(() => GoogleDriveService());
  sl.registerLazySingleton(() => FCMService());
  sl.registerLazySingletonAsync<FeatureDiscoveryService>(() async {
    final prefs = await SharedPreferences.getInstance();
    return FeatureDiscoveryService(prefs);
  });
}
