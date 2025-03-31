import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/add_evaluation_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/add_session_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/account_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/add_calendar_event_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/about_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/help_support_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/privacy_page.dart';
import 'package:go_router/go_router.dart';

class RoutingConfig {
  static final GoRouter router = GoRouter(
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
      default:
        return null;
    }
  }
}
