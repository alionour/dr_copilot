import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/add_calendar_event_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
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
        path: '/events/new',
        name: '/events/new',
        builder: (context, state) => const AddCalendarEventPage(),
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
      // Add more routes as needed
      default:
        return null;
    }
  }
}
