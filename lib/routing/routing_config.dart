import 'package:dr_copilot/auth/ui/auth_ui.dart';
import 'package:dr_copilot/pages/home/ui/home._ui.dart';
import 'package:go_router/go_router.dart';

// GoRouter configuration
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'signup',
      builder: (context, state) =>  SignUp(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const MyHomePage(
      
      ),
    ),
  ],
);
