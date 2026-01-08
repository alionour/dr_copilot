import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage feature discovery state (whether user has seen the tutorial).
class FeatureDiscoveryService {
  static const String _hasSeenFeatureDiscoveryKey =
      'has_seen_feature_discovery';

  final SharedPreferences _prefs;

  FeatureDiscoveryService(this._prefs);

  /// Returns true if the feature discovery should be shown (user hasn't seen it yet).
  Future<bool> shouldShowDiscovery() async {
    return !(_prefs.getBool(_hasSeenFeatureDiscoveryKey) ?? false);
  }

  /// Marks the feature discovery as seen.
  Future<void> markDiscoveryAsSeen() async {
    await _prefs.setBool(_hasSeenFeatureDiscoveryKey, true);
  }

  /// Resets the feature discovery state (for testing purposes).
  Future<void> resetDiscovery() async {
    await _prefs.remove(_hasSeenFeatureDiscoveryKey);
  }
}
