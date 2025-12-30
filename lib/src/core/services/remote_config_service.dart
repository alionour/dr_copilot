import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval:
            const Duration(hours: 1), // Use lower interval for dev
      ));

      await _remoteConfig.setDefaults(const {
        'signup_enabled': true,
        'max_allowed_users': 1000,
      });

      await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config initialized. signup_enabled: $isSignupEnabled');
    } catch (e) {
      debugPrint('Error initializing Remote Config: $e');
    }
  }

  bool get isSignupEnabled => _remoteConfig.getBool('signup_enabled');

  int get maxAllowedUsers => _remoteConfig.getInt('max_allowed_users');
}
