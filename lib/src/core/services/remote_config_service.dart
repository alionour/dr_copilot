import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> initialize() async {
    if (_isDesktop) {
      debugPrint('RemoteConfigService: Skipping initialization on desktop.');
      return;
    }
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval:
            const Duration(hours: 1), // Use lower interval for dev
      ));

      await _remoteConfig.setDefaults(const {
        'signup_enabled': true,
        'max_allowed_users': 1000,
        'enable_sensitive_scopes': false,
      });

      await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
    }
  }

  bool get isSignupEnabled {
    if (_isDesktop) return true;
    try {
      return _remoteConfig.getBool('signup_enabled');
    } catch (e) {
      debugPrint('Error getting signup_enabled: $e');
      return true; // Default
    }
  }

  int get maxAllowedUsers {
    if (_isDesktop) return 1000;
    try {
      return _remoteConfig.getInt('max_allowed_users');
    } catch (e) {
      debugPrint('Error getting max_allowed_users: $e');
      return 1000; // Default
    }
  }

  bool get enableSensitiveScopes {
    if (_isDesktop) return false;
    try {
      return _remoteConfig.getBool('enable_sensitive_scopes');
    } catch (e) {
      debugPrint('Error getting enable_sensitive_scopes: $e');
      return false; // Default
    }
  }
}
