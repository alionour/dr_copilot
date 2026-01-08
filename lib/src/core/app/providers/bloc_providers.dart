import 'package:dr_copilot/src/features/financials/transactions/presentation/bloc/transactions_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import '../../../features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/calendar/presentation/bloc/calendar_bloc.dart';
import '../../../features/copilot_chat/presentation/bloc/copilot_bloc.dart';
import '../../../features/financials/presentation/bloc/financials_bloc.dart';
import '../../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../../features/calendar_events/presentation/bloc/calendar_events_bloc.dart';
import '../../../features/inventory/presentation/bloc/inventory_bloc.dart';
import '../../../features/tasks/presentation/bloc/tasks_bloc.dart';

import '../../../features/navigation_side/presentation/bloc/navigation_bloc.dart';
import '../../../features/patients/presentation/bloc/patients_bloc.dart';
import '../../../features/doctors/presentation/bloc/doctors_bloc.dart';
import '../../../features/staff/presentation/bloc/staff_bloc.dart';
import '../../../features/settings/presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

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
      create: (context) => sl<AuthBloc>()..add(const AuthCheckRequested())),

  /// Provides a [NavigationBloc] instance to the widget tree.
  ///
  /// The bloc is initialized and immediately dispatched with a [GetUserData] event,
  /// which typically triggers the bloc to load user-related data upon creation.
  ///
  /// Usage of this provider allows descendant widgets to access and interact with
  /// the [NavigationBloc] for navigation and user data management.
  BlocProvider<NavigationBloc>(
    create: (context) => sl<NavigationBloc>(),
  ),

  /// Provides an instance of [PatientsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of a [PatientsBloc], making it available to all descendant widgets that
  /// require access to patient-related business logic and state management.
  ///
  /// Typically used at a high level in the widget tree to ensure that the
  /// [PatientsBloc] is accessible throughout the relevant scope of the application.
  BlocProvider<PatientsBloc>(create: (context) => sl<PatientsBloc>()),

  /// Provides an instance of [DoctorsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of a [DoctorsBloc], making it available to all descendant widgets that
  /// require access to doctor-related business logic and state management.
  ///
  /// Typically used at a high level in the widget tree to ensure that the
  /// [DoctorsBloc] is accessible throughout the relevant scope of the application.
  BlocProvider<DoctorsBloc>(create: (context) => sl<DoctorsBloc>()),

  /// Provides an instance of [StaffBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of a [StaffBloc], making it available to all descendant widgets that
  /// require access to staff-related business logic and state management.
  ///
  /// Typically used at a high level in the widget tree to ensure that the
  /// [StaffBloc] is accessible throughout the relevant scope of the application.
  BlocProvider<StaffBloc>(create: (context) => sl<StaffBloc>()),

  /// Provides an instance of [CopilotBloc] to the widget tree using [BlocProvider].
  ///
  /// The [CopilotBloc] is created with the given [context] and made available
  /// to all descendant widgets that require access to its state and events.
  BlocProvider<CopilotBloc>(create: (context) => sl<CopilotBloc>()),

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
  BlocProvider<SettingsBloc>(create: (context) => sl<SettingsBloc>()),

  /// Provides an instance of [SessionsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of a [SessionsBloc] instance, making it available to all descendant widgets
  /// that require access to session-related business logic and state management.
  ///
  /// The [create] function initializes the [SessionsBloc] using the provided
  /// [BuildContext].
  BlocProvider<SessionsBloc>(create: (context) => sl<SessionsBloc>()),

  /// Provides an instance of [EvaluationsBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of [EvaluationsBloc],
  /// making it available to all descendant widgets that require access to
  /// evaluation-related business logic and state management.
  ///
  /// Usage:
  /// Wrap your widget tree with this provider to access [EvaluationsBloc] via
  /// `BlocProvider.of<EvaluationsBloc>(context)`.
  BlocProvider<EvaluationsBloc>(create: (context) => sl<EvaluationsBloc>()),

  /// Provides an instance of [FinancialsBloc] to the widget tree.
  ///
  /// This [BlocProvider] is responsible for creating and managing the lifecycle
  /// of the [FinancialsBloc], making it available to all descendant widgets
  /// that require access to financial-related business logic and state.
  ///
  /// Usage:
  /// Wrap your widget tree with this provider to access [FinancialsBloc]
  /// using `BlocProvider.of<FinancialsBloc>(context)`.
  BlocProvider<FinancialsBloc>(create: (context) => sl<FinancialsBloc>()),

  /// Provides a [TransactionsBloc] instance to the widget tree.
  ///
  /// The [TransactionsBloc] is created using a [TransactionsUseCase], which in turn
  /// depends on a [TransactionsRepositoryImpl] that utilizes [TransactionsFirebaseApi]
  /// for data operations related to transactions.
  ///
  /// This provider enables descendant widgets to access and interact with the
  /// transactions business logic and state management.
  BlocProvider<TransactionsBloc>(
    create: (context) => sl<TransactionsBloc>(),
  ),

  /// Provides an instance of [CalendarBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of [CalendarBloc],
  /// making it available to all descendant widgets that require access to
  /// calendar functionality including Google Calendar integration and event management.
  BlocProvider<CalendarBloc>(
    create: (context) => sl<CalendarBloc>(),
  ),

  /// Provides an instance of [NotificationsBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of [NotificationsBloc],
  /// making it available to all descendant widgets that require access to
  /// notifications functionality including real-time updates from Firebase.
  BlocProvider<NotificationsBloc>(
    create: (context) => sl<NotificationsBloc>(),
  ),

  /// Provides an instance of [CalendarEventsBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of [CalendarEventsBloc],
  /// making it available to all descendant widgets that require access to
  /// calendar events functionality including real-time streaming.
  BlocProvider<CalendarEventsBloc>(
    create: (context) => sl<CalendarEventsBloc>(),
  ),

  /// Provides an instance of [InventoryBloc] to the widget tree.
  ///
  /// This [BlocProvider] creates and manages the lifecycle of [InventoryBloc],
  /// making it available to all descendant widgets that require access to
  /// inventory management functionality.
  BlocProvider<InventoryBloc>(
    create: (context) => sl<InventoryBloc>(),
  ),

  /// Provides an instance of [TasksBloc] to the widget tree.
  BlocProvider<TasksBloc>(
    create: (context) => sl<TasksBloc>(),
  ),
];
