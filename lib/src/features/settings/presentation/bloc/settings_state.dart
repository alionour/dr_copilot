part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLightMode extends SettingsState {}

class SettingsDarkMode extends SettingsState {}

class SettingsLocale extends SettingsState {
  final String localeCode;

  const SettingsLocale(this.localeCode);

  @override
  List<Object> get props => [localeCode];
}

