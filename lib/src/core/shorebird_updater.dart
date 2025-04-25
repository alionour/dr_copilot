import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Handles Shorebird code push update logic.
class ShorebirdCodePushHandler {
  /// Checks for and applies updates on app startup.
  static Future<void> checkAndApplyUpdate() async {
    final updater = ShorebirdUpdater();
    final updateStatus = await updater.checkForUpdate();
    if (updateStatus == UpdateStatus.outdated) {
      try {
        await updater.update(); // Restarts the app if an update is applied
      } catch (e) {
        // Optionally log or handle update errors
      }
    }
  }
}
