import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
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
