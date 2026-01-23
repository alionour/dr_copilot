import 'package:flutter/foundation.dart';

// ignore: depend_on_referenced_packages
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// A handler class for managing Shorebird code push updates.
///
/// This class provides functionality to check for available updates
/// and apply them when the app starts. If an update is available,
/// it attempts to apply the update and restart the app. Any errors
/// encountered during the update process are caught and can be logged.
/// Handles Shorebird code push update logic.
class ShorebirdCodePushHandler {
  /// Checks for and applies updates on app startup.
  /// Checks for available updates and applies them if found.
  ///
  /// This method asynchronously checks whether an update is available for the application.
  /// If an update is detected, it proceeds to apply the update automatically.
  ///
  /// Throws an [Exception] if the update process fails.
  ///
  /// Example:
  /// ```dart
  /// await checkAndApplyUpdate();
  /// ```
  static Future<void> checkAndApplyUpdate() async {
    // Shorebird supports Android, iOS, Windows, macOS, and Linux (as of early 2025).
    // We only skip web platform.
    if (kIsWeb) {
      debugPrint('Shorebird update check skipped: Web platform not supported.');
      return;
    }

    try {
      /// Creates an instance of [ShorebirdUpdater] to manage application updates.
      final updater = ShorebirdUpdater();

      /// Checks for available updates using the updater and stores the result in [updateStatus].
      ///
      /// This call is asynchronous and awaits the result of [updater.checkForUpdate()],
      /// which typically returns information about whether an update is available,
      /// the current version, and other relevant update metadata.
      final updateStatus = await updater.checkForUpdate();

      /// Checks if the current update status indicates that the application is outdated.
      /// If `updateStatus` equals `UpdateStatus.outdated`, it means a newer version of the app is available.
      if (updateStatus == UpdateStatus.outdated) {
        debugPrint('Shorebird update found. Downloading...');
        await updater.update(); // Restarts the app if an update is applied
      } else {
        debugPrint('Shorebird: No updates available.');
      }
    } catch (e) {
      // Optionally log or handle update errors
      debugPrint('Error applying Shorebird update: $e');
    }
  }
}
