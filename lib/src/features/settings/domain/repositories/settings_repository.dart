import 'package:dr_copilot/src/features/settings/domain/models/clinic_settings_model.dart';
import 'package:dr_copilot/src/features/settings/domain/models/user_settings_model.dart';

abstract class SettingsRepository {
  Stream<UserSettingsModel> getUserSettings();
  Stream<ClinicSettingsModel> getClinicSettings(String clinicId);
  Future<void> updateUserSettings(UserSettingsModel settings);
  Future<void> updateClinicSettings(
      String clinicId, ClinicSettingsModel settings);
}
