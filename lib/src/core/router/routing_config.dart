import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/navigation_side.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/sessions_page.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/evaluations_page.dart';
import 'package:dr_copilot/src/features/charts/presentation/pages/charts_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/financials_page.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/pages/clinical_reports_list_page.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/pages/chatgpt_project_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/account_page.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/presentation/pages/live_voice_assistant_page.dart';
import 'package:dr_copilot/src/features/doctors/presentation/pages/doctors_page.dart';
import 'package:dr_copilot/src/features/staff/presentation/pages/staff_page.dart';
import 'package:dr_copilot/src/shared/presentation/widgets/webview_screen.dart';
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
      ShellRoute(
        builder: (context, state, child) {
          return NavigationSide(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const CopilotPage(title: 'Chat'),
          ),
          GoRoute(
            path: '/patients',
            name: 'patients',
            builder: (context, state) => const PatientsPage(),
          ),
          GoRoute(
            path: '/sessions',
            name: 'sessions',
            builder: (context, state) => const SessionsPage(),
          ),
          GoRoute(
            path: '/evaluations',
            name: 'evaluations',
            builder: (context, state) => const EvaluationsPage(),
          ),
          GoRoute(
            path: '/charts',
            name: 'charts',
            builder: (context, state) => const ChartsPage(),
          ),
          GoRoute(
            path: '/financials',
            name: 'financials',
            builder: (context, state) => const FinancialsPage(),
          ),
          GoRoute(
            path: '/clinical_reports',
            name: 'clinical_reports',
            builder: (context, state) => const ClinicalReportsListPage(),
          ),
          GoRoute(
            path: '/chatgpt_project',
            name: 'chatgpt_project',
            builder: (context, state) => const ChatGptProjectPage(),
          ),
          GoRoute(
            path: '/live_assistant',
            name: 'live_assistant',
            builder: (context, state) => const LiveVoiceAssistantPage(),
          ),
          GoRoute(
            path: '/doctors',
            name: 'doctors',
            builder: (context, state) => const DoctorsPage(),
          ),
          GoRoute(
            path: '/staff',
            name: 'staff',
            builder: (context, state) => const StaffPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/webview',
        name: 'webview',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'Web View';
          final url = state.uri.queryParameters['url'];
          if (url == null) {
            return const ErrorRoutePage();
          }
          return WebViewScreen(title: title, url: url);
        },
      ),
    ],
  );
}

class ErrorRoutePage extends StatelessWidget {
  const ErrorRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('errorPageTitle'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'errorPageMessage'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                child: Text('goToHome'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
