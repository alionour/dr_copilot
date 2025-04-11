import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/add_evaluation_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/add_session_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/account_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/add_calendar_event_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/add_transaction_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/about_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/help_support_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/privacy_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoutingConfig {
  static final GoRouter router = GoRouter(
    errorBuilder: (context, state) => const ErrorRoutePage(),
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
        path: '/patients/new',
        name: '/patients/new',
        builder: (context, state) => const AddPatientPage(),
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
        path: '/add_transaction',
        name: 'add_transaction',
        builder: (context, state) => const AddTransactionPage(),
      ),
    ],
  );

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
