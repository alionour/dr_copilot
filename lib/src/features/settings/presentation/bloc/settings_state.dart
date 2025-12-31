part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final String localeCode;
  final List<String> copilotRequiredFields;
  final List<int> workingDays;
  final bool usePremiumModels;

  const SettingsState({
    this.isDarkMode = false,
    this.localeCode = 'en',
    this.copilotRequiredFields = const [],
    this.workingDays = const [1, 2, 3, 4, 5], // Default: Mon-Fri
    this.usePremiumModels = false,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? localeCode,
    List<String>? copilotRequiredFields,
    List<int>? workingDays,
    bool? usePremiumModels,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      localeCode: localeCode ?? this.localeCode,
      copilotRequiredFields:
          copilotRequiredFields ?? this.copilotRequiredFields,
      workingDays: workingDays ?? this.workingDays,
      usePremiumModels: usePremiumModels ?? this.usePremiumModels,
    );
  }

  @override
  List<Object> get props => [
        isDarkMode,
        localeCode,
        copilotRequiredFields,
        workingDays,
        usePremiumModels
      ];
}
