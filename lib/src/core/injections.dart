import 'package:dr_copilot/src/features/appointments/evaluations/evaluations_injections.dart';
import 'package:dr_copilot/src/features/appointments/sessions/sessions_injections.dart';
import 'package:dr_copilot/src/features/auth/auth_injections.dart';
import 'package:dr_copilot/src/features/financials/financials_injections.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/core/network/network_info.dart';
import 'package:dr_copilot/src/features/patients/patients_injections.dart';

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

  // Features
  /// Initializes the dependency injections related to patients.
  /// 
  /// This function sets up all necessary services and dependencies required
  /// for patient-related features within the application. It should be called
  /// during the application's initialization phase to ensure that all patient
  /// services are properly registered and available for use.
  initPatientsInjections();
  
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
  /// for financial features within the application.
  initFinancialsInjections();
  
  /// Initializes the dependency injections required for session management.
  /// 
  /// This function sets up all necessary services and dependencies related to
  /// user sessions, ensuring they are available throughout the application.
  /// Call this during the application's initialization phase.
  initSessionsInjections();  


  /// Initializes the dependency injections required for authentication features.
  /// 
  /// This function sets up and registers all necessary services, repositories,
  /// and providers related to authentication in the application's dependency
  /// injection system. It should be called during the application's startup
  /// or initialization phase to ensure authentication components are available
  /// throughout the app.
  initAuthInjections();

}
