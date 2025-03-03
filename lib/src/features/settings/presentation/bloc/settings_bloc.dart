import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<ToggleThemeEvent>(_toggleTheme);
    on<LoadSettingsEvent>(_loadSettings);
  }

  void _toggleTheme(ToggleThemeEvent event, Emitter<SettingsState> emit) async {
    final isDarkMode = state is SettingsDarkMode;
    final newState = isDarkMode ? SettingsLightMode() : SettingsDarkMode();
    emit(newState);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', !isDarkMode);
  }

  void _loadSettings(
      LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    emit(isDarkMode ? SettingsDarkMode() : SettingsLightMode());
  }
}
