import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';
import 'package:dr_copilot/src/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import '../../../features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import '../../../features/appointments/evaluations/data/repositories/evaluations_repository_impl.dart';
import '../../../features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import '../../../features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import '../../../features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import '../../../features/appointments/sessions/data/repositories/sessions_repository_impl.dart';
import '../../../features/appointments/sessions/data/remote/session_firebase_api.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/copilot_chat/presentation/bloc/copilot_bloc.dart';
import '../../../features/copilot_chat/services/claude_service.dart';
import '../../../features/copilot_chat/services/deepseek_service.dart';
import '../../../features/copilot_chat/services/gemini_service.dart';
import '../../../features/copilot_chat/services/gpt_service.dart';
import '../../../features/copilot_chat/services/qwen_service.dart';
import '../../../features/copilot_chat/services/vertex_ai_service.dart';
import '../../../features/financials/presentation/bloc/financials_bloc.dart';
import '../../../features/financials/domain/usecases/financials_usecase.dart';
import '../../../features/financials/data/repositories/financials_repository_impl.dart';
import '../../../features/financials/data/remote/financials_firebase_api.dart';
import '../../../features/navigation_side/presentation/bloc/navigation_bloc.dart';
import '../../../features/patients/presentation/bloc/patients_bloc.dart';
import '../../../features/patients/domain/usecases/patients_usecase.dart';
import '../../../features/patients/data/repositories/patients_repo_impl.dart';
import '../../../features/patients/data/remote/patient_firebase_api.dart';
import '../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../helper/api_key_helper.dart';

/// A list of [BlocProvider]s used to provide various BLoC instances throughout the app.
///
/// This includes providers for authentication, navigation, patients, copilot AI services,
/// settings, sessions, evaluations, and financials. Each BLoC is initialized with its
/// respective dependencies, such as use cases, repositories, and API services.
///
/// The list is intended to be used in the widget tree to make these BLoC instances
/// available to descendant widgets via the `Provider` package.

final appBlocProviders = <BlocProvider<dynamic>>[
  /// Provides an instance of [AuthBloc] to the widget tree, allowing descendant widgets
  /// to access authentication-related state and events using the BLoC pattern.
  ///
  /// This provider should be placed above any widgets that need to interact with
  /// authentication logic, such as login, logout, or user session management.
  BlocProvider<AuthBloc>(
      create: (context) =>
          AuthBloc(AuthUseCase(AuthRepositoryImpl(AuthFirebaseApi())))),

  /// Provides a [NavigationBloc] instance to the widget tree.
  ///
  /// The bloc is initialized and immediately dispatched with a [GetUserData] event,
  /// which typically triggers the bloc to load user-related data upon creation.
  ///
  /// Usage of this provider allows descendant widgets to access and interact with
  /// the [NavigationBloc] for navigation and user data management.
  BlocProvider<NavigationBloc>(
      create: (context) => NavigationBloc()..add(GetUserData())),

  /// Provides an instance of [PatientsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of a [PatientsBloc], making it available to all descendant widgets that
  /// require access to patient-related business logic and state management.
  ///
  /// Typically used at a high level in the widget tree to ensure that the
  /// [PatientsBloc] is accessible throughout the relevant scope of the application.
  BlocProvider<PatientsBloc>(
      create: (context) => PatientsBloc(
            PatientsUseCase(PatientsRepositoryImpl(PatientFirebaseApi())),
          )),

  /// Provides an instance of [CopilotBloc] to the widget tree using [BlocProvider].
  ///
  /// The [CopilotBloc] is created with the given [context] and made available
  /// to all descendant widgets that require access to its state and events.
  BlocProvider<CopilotBloc>(
      create: (context) => CopilotBloc(
            vertexAIService: VertexAIService(ApiKeyHelper.vertexAIKey),
            gptService: GPTService(ApiKeyHelper.gptKey),
            geminiService: GeminiService(ApiKeyHelper.geminiKey),
            deepSeekService: DeepSeekService(ApiKeyHelper.deepSeekKey),
            qwenService: QwenService(ApiKeyHelper.qwenKey),
            claudeService: ClaudeService(ApiKeyHelper.claudeKey),
          )),

  /// Provides an instance of [SettingsBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of a [SettingsBloc],
  /// making it available to all descendant widgets that require access to
  /// settings-related state and logic.
  ///
  /// Example usage:
  /// ```dart
  /// BlocProvider<SettingsBloc>(
  ///   create: (context) => SettingsBloc(),
  ///   child: MyApp(),
  /// )
  /// ```
  BlocProvider<SettingsBloc>(create: (context) => SettingsBloc()),

  /// Provides an instance of [SessionsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of a [SessionsBloc] instance, making it available to all descendant widgets
  /// that require access to session-related business logic and state management.
  ///
  /// The [create] function initializes the [SessionsBloc] using the provided
  /// [BuildContext].
  BlocProvider<TransactionsBloc>(
      create: (context) => TransactionsBloc(
            SessionsUseCase(SessionsRepositoryImpl(SessionsFirebaseApi())),
          )),

  /// Provides an instance of [EvaluationsBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of [EvaluationsBloc],
  /// making it available to all descendant widgets that require access to
  /// evaluation-related business logic and state management.
  ///
  /// Usage:
  /// Wrap your widget tree with this provider to access [EvaluationsBloc] via
  /// `BlocProvider.of<EvaluationsBloc>(context)`.
  BlocProvider<EvaluationsBloc>(
      create: (context) => EvaluationsBloc(
            EvaluationsUseCase(
                EvaluationsRepositoryImpl(EvaluationsFirebaseApi())),
          )),

  /// Provides an instance of [FinancialsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of the [FinancialsBloc], making it available to all descendant widgets
  /// that require access to financial-related business logic and state.
  ///
  /// Usage:
  /// Wrap your widget tree with this provider to access [FinancialsBloc]
  /// using `BlocProvider.of<FinancialsBloc>(context)`.
  BlocProvider<FinancialsBloc>(
      create: (context) => FinancialsBloc(
            FinancialsUseCase(
                FinancialsRepositoryImpl(FinancialsFirebaseApi())),
          )),
];
