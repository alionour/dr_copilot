import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  SettingsBloc() : super(SettingsInitial()) {
    on<ToggleThemeEvent>(_toggleTheme);
    on<LoadSettingsEvent>(_loadSettings);
    on<ChangeLocaleEvent>(_changeLocale);
  }

  void _toggleTheme(ToggleThemeEvent event, Emitter<SettingsState> emit) async {
    final isDarkMode = state is SettingsDarkMode;
    final newState = isDarkMode ? SettingsLightMode() : SettingsDarkMode();
    emit(newState);
    await secureStorage.write(
        key: 'isDarkMode', value: (!isDarkMode).toString());
  }

  void _loadSettings(
      LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    final isDarkModeStr = await secureStorage.read(key: 'isDarkMode');
    final isDarkMode = isDarkModeStr == null ? false : isDarkModeStr == 'true';
    emit(isDarkMode ? SettingsDarkMode() : SettingsLightMode());
  }

  void _changeLocale(
      ChangeLocaleEvent event, Emitter<SettingsState> emit) async {
    await secureStorage.write(key: 'localeCode', value: event.localeCode);
    emit(SettingsLocale(event.localeCode));
  }
}

