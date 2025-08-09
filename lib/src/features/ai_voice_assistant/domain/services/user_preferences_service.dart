import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  final SharedPreferences _prefs;

  UserPreferencesService(this._prefs);

  static const String _sessionDurationKey = 'session_duration';

  Future<void> setPreferredSessionDuration(int duration) async {
    await _prefs.setInt(_sessionDurationKey, duration);
  }

  int? getPreferredSessionDuration() {
    return _prefs.getInt(_sessionDurationKey);
  }
}
