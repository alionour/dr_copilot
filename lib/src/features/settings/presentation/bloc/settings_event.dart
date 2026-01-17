part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class ToggleThemeEvent extends SettingsEvent {}

class LoadSettingsEvent extends SettingsEvent {}

class ChangeLocaleEvent extends SettingsEvent {
  final String localeCode;

  const ChangeLocaleEvent(this.localeCode);

  @override
  List<Object> get props => [localeCode];
}

class UpdateCopilotFieldEvent extends SettingsEvent {
  final List<String> requiredFields;

  const UpdateCopilotFieldEvent(this.requiredFields);

  @override
  List<Object> get props => [requiredFields];
}

class UpdateWorkingDaysEvent extends SettingsEvent {
  final List<int> workingDays;

  const UpdateWorkingDaysEvent(this.workingDays);

  @override
  List<Object> get props => [workingDays];
}

class TogglePremiumModelsEvent extends SettingsEvent {}
