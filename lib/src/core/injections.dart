import 'package:dr_copilot/src/features/appointments/evaluations/evaluations_injections.dart';
import 'package:dr_copilot/src/features/appointments/sessions/sessions_injections.dart';
import 'package:dr_copilot/src/features/auth/auth_injections.dart';
import 'package:dr_copilot/src/core/services/services_injections.dart';
import 'package:dr_copilot/src/features/calendar/calendar_injections.dart';
import 'package:dr_copilot/src/features/copilot_chat/copilot_injections.dart';
import 'package:dr_copilot/src/features/clinical_reports/clinical_reports_injections.dart';
import 'package:dr_copilot/src/features/chatgpt_project/chatgpt_project_injections.dart';
import 'package:dr_copilot/src/features/financials/financials_injections.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/live_voice_assistant_injections.dart';
import 'package:dr_copilot/src/features/navigation_side/navigation_side_injections.dart';
import 'package:dr_copilot/src/features/settings/settings_injections.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/core/network/network_info.dart';
import 'package:dr_copilot/src/features/patients/patients_injections.dart';
import 'package:dr_copilot/src/features/doctors/doctors_injections.dart';
import 'package:dr_copilot/src/features/staff/staff_injections.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Import other feature injection files as needed
/// Initializes dependency injection for the application using GetIt.
///
/// This function registers core and feature-specific dependencies as lazy singletons.
///
/// - Registers [NetworkInfo] implementation as a singleton.
/// - Initializes dependency injections for Patients, Evaluations, Financials, and Sessions features.
/// - Extend this function to add more feature injection initializations as the app grows.
///
/// Usage:
/// ```dart
/// await initInjections();
/// ```

final sl = GetIt.instance;

Future<void> initInjections() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  initServicesInjections();

  // Features (order matters due to dependencies)
  /// Initializes the dependency injections related to patients.
  ///
  /// This function sets up all necessary services and dependencies required
  /// for patient-related features within the application. It should be called
  /// during the application's initialization phase to ensure that all patient
  /// services are properly registered and available for use.
  initPatientsInjections();
  initDoctorsInjections();
  initStaffInjections();

  /// Initializes the dependency injections required for session management.
  ///
  /// This function sets up all necessary services and dependencies related to
  /// user sessions, ensuring they are available throughout the application.
  /// Call this during the application's initialization phase.
  initSessionsInjections();

  /// Initializes the dependency injections required for the evaluations feature/module.
  ///
  /// This function sets up all necessary services, repositories, and other dependencies
  /// related to evaluations, ensuring they are available for use throughout the application.
  ///
  /// Typically called during the application's startup or initialization phase.
  initEvaluationsInjections();

  /// Initializes the dependency injections related to financial modules or services.
  ///
  /// This function should be called to set up all necessary dependencies required
  /// for financial features within the application. Must be called after sessions
  /// and evaluations as it depends on their use cases.
  initFinancialsInjections();

  /// Initializes the dependency injections required for authentication features.
  ///
  /// This function sets up and registers all necessary services, repositories,
  /// and providers related to authentication in the application's dependency
  /// injection system. It should be called during the application's startup
  /// or initialization phase to ensure authentication components are available
  /// throughout the app.
  initAuthInjections();

  /// Initializes the dependency injections required for the navigation side feature.
  ///
  /// This function sets up all necessary services and dependencies related to
  /// navigation and side menu functionality, ensuring they are available throughout
  /// the application. Call this during the application's initialization phase.
  initNavigationSideInjections();

  /// Initializes the dependency injections required for the copilot chat feature.
  ///
  /// This function sets up all necessary services and dependencies related to
  /// AI chat functionality, ensuring they are available throughout the application.
  /// Call this during the application's initialization phase.
  initCopilotInjections();

  /// Initializes the dependency injections required for the Live Voice Assistant feature.
  ///
  /// This function sets up all necessary services, repositories, and use cases
  /// related to voice interaction, speech recognition, text-to-speech, and AI
  /// conversation management. It should be called during the application's
  /// initialization phase to ensure voice assistant components are available.
  /// NOTE: Must be called after copilot injections as it depends on AI services.
  initLiveVoiceAssistantInjections();

  /// Initializes the dependency injections required for the settings feature.
  ///
  /// This function sets up all necessary services and dependencies related to
  /// application settings, ensuring they are available throughout the application.
  /// Call this during the application's initialization phase.
  initSettingsInjections();

  /// Initializes the dependency injections required for the calendar feature.
  ///
  /// This function sets up all necessary services and dependencies related to
  /// calendar functionality, ensuring they are available throughout the application.
  /// Call this during the application's initialization phase.
  initCalendarInjections();
  initClinicalReportsInjections();
  initChatGptProjectInjections();
}
