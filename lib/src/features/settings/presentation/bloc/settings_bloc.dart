import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/settings/domain/models/clinic_settings_model.dart';
import 'package:dr_copilot/src/features/settings/domain/models/user_settings_model.dart';
import 'package:dr_copilot/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository repository;
  final OwnerNotifier ownerNotifier;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  StreamSubscription<UserSettingsModel>? _userSettingsSubscription;
  StreamSubscription<ClinicSettingsModel>? _clinicSettingsSubscription;

  SettingsBloc({
    required this.repository,
    required this.ownerNotifier,
  }) : super(const SettingsState()) {
    on<ToggleThemeEvent>(_toggleTheme);
    on<LoadSettingsEvent>(_loadSettings);
    on<ChangeLocaleEvent>(_changeLocale);
    on<UpdateCopilotFieldEvent>(_updateCopilotFields);
    on<UpdateWorkingDaysEvent>(_updateWorkingDays);
    on<TogglePremiumModelsEvent>(_togglePremiumModels);
    on<_UpdateUserSettings>((event, emit) {
      emit(state.copyWith(
        isDarkMode: event.settings.isDarkMode ?? state.isDarkMode,
        localeCode: event.settings.localeCode ?? state.localeCode,
        usePremiumModels:
            event.settings.usePremiumModels ?? state.usePremiumModels,
      ));
    });
    on<_UpdateClinicSettings>((event, emit) {
      emit(state.copyWith(
        workingDays: event.settings.workingDays,
        copilotRequiredFields: event.settings.copilotRequiredFields,
      ));
    });
  }

  @override
  Future<void> close() {
    _userSettingsSubscription?.cancel();
    _clinicSettingsSubscription?.cancel();
    return super.close();
  }

  void _loadSettings(
      LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    // Cancel existing subscriptions
    await _userSettingsSubscription?.cancel();
    await _clinicSettingsSubscription?.cancel();

    // Subscribe to User Settings
    _userSettingsSubscription = repository.getUserSettings().listen(
      (settings) {
        add(_UpdateUserSettings(settings));
      },
    );

    // Subscribe to Clinic Settings
    final clinicId = ownerNotifier.clinicId;
    if (clinicId != null && clinicId.isNotEmpty) {
      _clinicSettingsSubscription =
          repository.getClinicSettings(clinicId).listen((settings) {
        add(_UpdateClinicSettings(settings));
      });
    }

    // Still load local biometric setting?
    // It's handled in SecuritySettingsPage individually, but if we wanted it in state...
    // Current state doesn't seem to track biometrics, so skipping.
  }

  void _toggleTheme(ToggleThemeEvent event, Emitter<SettingsState> emit) async {
    final newMode = !state.isDarkMode;
    // Optimistic update
    emit(state.copyWith(isDarkMode: newMode));

    // Save to User Settings
    await repository.updateUserSettings(UserSettingsModel(isDarkMode: newMode));
  }

  void _changeLocale(
      ChangeLocaleEvent event, Emitter<SettingsState> emit) async {
    // Optimistic update
    emit(state.copyWith(localeCode: event.localeCode));

    // Save to User Settings
    await repository
        .updateUserSettings(UserSettingsModel(localeCode: event.localeCode));
  }

  bool get _canEditClinicSettings {
    return ownerNotifier.hasPermission(AppPermission.manageSettings);
  }

  void _updateCopilotFields(
      UpdateCopilotFieldEvent event, Emitter<SettingsState> emit) async {
    if (!_canEditClinicSettings) return;

    final clinicId = ownerNotifier.clinicId;
    if (clinicId == null) return;

    // Optimistic update
    emit(state.copyWith(copilotRequiredFields: event.requiredFields));

    await repository.updateClinicSettings(
      clinicId,
      ClinicSettingsModel(
          copilotRequiredFields: event.requiredFields,
          workingDays: state.workingDays),
    );
  }

  void _updateWorkingDays(
      UpdateWorkingDaysEvent event, Emitter<SettingsState> emit) async {
    if (!_canEditClinicSettings) return;

    final clinicId = ownerNotifier.clinicId;
    if (clinicId == null) return;

    // Optimistic update
    emit(state.copyWith(workingDays: event.workingDays));

    await repository.updateClinicSettings(
      clinicId,
      ClinicSettingsModel(
          workingDays: event.workingDays,
          copilotRequiredFields: state.copilotRequiredFields),
    );
  }

  void _togglePremiumModels(
      TogglePremiumModelsEvent event, Emitter<SettingsState> emit) async {
    final newValue = !state.usePremiumModels;
    // Optimistic update
    emit(state.copyWith(usePremiumModels: newValue));

    // Save to User Settings
    await repository
        .updateUserSettings(UserSettingsModel(usePremiumModels: newValue));
  }
}

// Internal events for stream updates
class _UpdateUserSettings extends SettingsEvent {
  final UserSettingsModel settings;
  const _UpdateUserSettings(this.settings);
  @override
  List<Object> get props => [settings];
}

class _UpdateClinicSettings extends SettingsEvent {
  final ClinicSettingsModel settings;
  const _UpdateClinicSettings(this.settings);
  @override
  List<Object> get props => [settings];
}
