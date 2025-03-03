import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsInitial()) {
    on<ToggleThemeEvent>(_toggleTheme);
  }

  void _toggleTheme(ToggleThemeEvent event, Emitter<SettingsState> emit) {
    final isDarkMode = state is SettingsDarkMode;
    emit(isDarkMode ? SettingsLightMode() : SettingsDarkMode());
  }
}
