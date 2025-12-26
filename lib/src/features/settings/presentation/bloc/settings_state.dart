part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final String localeCode;
  final List<String> copilotRequiredFields;
  final List<int> workingDays;

  const SettingsState({
    this.isDarkMode = false,
    this.localeCode = 'en',
    this.copilotRequiredFields = const [],
    this.workingDays = const [1, 2, 3, 4, 5], // Default: Mon-Fri
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? localeCode,
    List<String>? copilotRequiredFields,
    List<int>? workingDays,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      localeCode: localeCode ?? this.localeCode,
      copilotRequiredFields:
          copilotRequiredFields ?? this.copilotRequiredFields,
      workingDays: workingDays ?? this.workingDays,
    );
  }

  @override
  List<Object> get props =>
      [isDarkMode, localeCode, copilotRequiredFields, workingDays];
}
