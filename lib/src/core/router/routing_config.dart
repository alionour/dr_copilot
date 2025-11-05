import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/add_evaluation_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/add_session_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/account_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/add_calendar_event_page.dart';
import 'package:dr_copilot/src/features/financials/transactions/presentation/pages/add_transaction_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/presentation/pages/live_voice_assistant_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/doctors/presentation/pages/doctors_page.dart';
import 'package:dr_copilot/src/features/doctors/presentation/pages/add_edit_doctor_page.dart';
import 'package:dr_copilot/src/features/staff/presentation/pages/add_edit_staff_page.dart';
import 'package:dr_copilot/src/features/staff/presentation/pages/staff_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/about_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/help_support_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/privacy_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A configuration class for defining routing settings and behaviors within the application.
///
/// Use this class to specify and manage route-related options, such as route paths,
/// navigation rules, and other routing-specific configurations.
class RoutingConfig {
  /// A static instance of [GoRouter] used to configure and manage the application's routing.
  ///
  /// This router defines the navigation logic and available routes within the app.
  /// It should be used throughout the application to handle route transitions and deep linking.
  static final GoRouter router = GoRouter(
    /// A builder function that returns the widget to display when a routing error occurs.
    ///
    /// The [context] provides the location in the widget tree, and [state] contains
    /// information about the current routing state. This builder returns an instance
    /// of [ErrorRoutePage] to inform the user about the navigation error.
    errorBuilder: (context, state) => const ErrorRoutePage(),

    /// A list of route configurations used to define the navigation structure of the application.
    /// Each entry in the list represents a route and its associated settings, such as path, widget,
    /// and any route-specific guards or parameters.
    routes: [
      GoRoute(
        path: '/',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/live_assistant',
        name: 'live_assistant',
        builder: (context, state) => const LiveVoiceAssistantPage(),
      ),
      GoRoute(
        path: '/patients/new',
        name: '/patients/new',
        builder: (context, state) => const AddPatientPage(),
      ),
      GoRoute(
        path: '/doctors',
        name: 'doctors',
        builder: (context, state) => const DoctorsPage(),
      ),
      GoRoute(
        path: '/doctors/new',
        name: 'add_doctor',
        builder: (context, state) => const AddEditDoctorPage(),
      ),
      GoRoute(
        path: '/doctors/:doctorId/edit',
        name: 'edit_doctor',
        builder: (context, state) => AddEditDoctorPage(
          doctorId: state.pathParameters['doctorId'],
        ),
      ),
      GoRoute(
        path: '/staff',
        name: 'staff',
        builder: (context, state) => const StaffPage(),
      ),
      GoRoute(
        path: '/staff/new',
        name: 'add_staff',
        builder: (context, state) => const AddEditStaffPage(),
      ),
      GoRoute(
        path: '/staff/:staffId/edit',
        name: 'edit_staff',
        builder: (context, state) => AddEditStaffPage(
          staffId: state.pathParameters['staffId'],
        ),
      ),
      GoRoute(
        path: '/sessions/new',
        name: '/sessions/new',
        builder: (context, state) => const AddSessionPage(),
      ),
      GoRoute(
        path: '/evaluations/new',
        name: '/evaluations/new',
        builder: (context, state) => const AddEvaluationPage(),
      ),
      GoRoute(
        path: '/events/new',
        name: '/events/new',
        builder: (context, state) => const AddCalendarEventPage(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: '/help_support',
        name: 'help_support',
        builder: (context, state) => const HelpSupportPage(),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/transactions/new',
        name: 'add_transaction',
        builder: (context, state) => const AddTransactionPage(),
      ),
    ],
  );

  /// Returns the [GoRoute] that matches the given [path], or `null` if no match is found.
  ///
  /// [path]: The route path to search for.
  ///
  /// Returns a [GoRoute] if a matching route exists, otherwise returns `null`.
  GoRoute? getRoute(String path) {
    switch (path) {
      case '/':
        return GoRoute(
            path: '/',
            name: 'login',
            builder: (context, state) => const LoginPage());
      case '/home':
        return GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage());
      case '/sessions/new':
        return GoRoute(
            path: '/sessions/new',
            name: '/sessions/new',
            builder: (context, state) => const AddSessionPage());
      case '/evaluations/new':
        return GoRoute(
            path: '/evaluations/new',
            name: '/evaluations/new',
            builder: (context, state) => const AddEvaluationPage());
      case '/events/new':
        return GoRoute(
            path: '/events/new',
            name: '/events/new',
            builder: (context, state) => const AddCalendarEventPage());
      case '/patients/new':
        return GoRoute(
            path: '/patients/new',
            name: '/patients/new',
            builder: (context, state) => const AddPatientPage());
      case '/about':
        return GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => const AboutPage());
      case '/help_support':
        return GoRoute(
            path: '/help_support',
            name: 'help_support',
            builder: (context, state) => const HelpSupportPage());
      case '/privacy':
        return GoRoute(
            path: '/privacy',
            name: 'privacy',
            builder: (context, state) => const PrivacyPage());
      case '/add_transaction':
        return GoRoute(
            path: '/add_transaction',
            name: '/add_transaction',
            builder: (context, state) => const AddTransactionPage());
      case '/account':
        return GoRoute(
            path: '/account',
            name: 'account',
            builder: (context, state) => const AccountPage());

      default:
        return null;
    }
  }
}

/// A [StatelessWidget] that represents a page displayed when a routing error occurs.
///
/// Typically used to show an error message or fallback UI when navigation fails
/// or an invalid route is accessed within the application.
class ErrorRoutePage extends StatelessWidget {
  const ErrorRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('errorPageTitle'.tr()), // Example: "Page Not Found"
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to the previous page
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'errorPageMessage'
                    .tr(), // Example: "The page you are looking for does not exist."
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to the home page
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: Text('goToHome'.tr()), // Example: "Go to Home"
              ),
            ],
          ),
        ),
      ),
    );
  }
}
