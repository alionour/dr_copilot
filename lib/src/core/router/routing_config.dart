import 'package:dr_copilot/src/features/auth/presentation/pages/signup_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/navigation_side.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/calendar_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/notifications_page.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/pages/copilot_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/sessions_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/pages/add_session_page.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/evaluations_page.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/pages/add_evaluation_page.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/charts/presentation/pages/charts_page.dart';
import 'package:dr_copilot/src/features/financials/presentation/pages/financials_page.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/pages/clinical_reports_list_page.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/pages/add_edit_clinical_report_page.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/pages/create_clinical_report_page.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/pages/clinical_report_details_page.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/pages/chatgpt_project_list_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/api_key_settings_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/help_support_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/about_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/privacy_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/notifications_settings_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/security_settings_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/data_storage_settings_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/export_data_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/account_page.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/model_selection_page.dart';

import 'package:dr_copilot/src/features/doctors/presentation/pages/doctors_page.dart';
import 'package:dr_copilot/src/features/staff/presentation/pages/staff_page.dart';
import 'package:dr_copilot/src/features/staff/presentation/pages/add_edit_staff_page.dart';
import 'package:dr_copilot/src/features/invitations/presentation/pages/invitations_page.dart';
import 'package:dr_copilot/src/features/invitations/presentation/pages/create_invitation_page.dart';
import 'package:dr_copilot/src/features/invitations/presentation/pages/accept_invitation_page.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/shared/presentation/widgets/webview_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

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
          return SelectionArea(child: NavigationSide(child: child));
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
            path: '/settings/notifications',
            name: 'notifications_settings',
            builder: (context, state) => const NotificationsSettingsPage(),
          ),
          GoRoute(
            path: '/settings/security',
            name: 'security_settings',
            builder: (context, state) => const SecuritySettingsPage(),
          ),
          GoRoute(
            path: '/settings/data_storage',
            name: 'data_storage_settings',
            builder: (context, state) => const DataStorageSettingsPage(),
          ),
          GoRoute(
            path: '/settings/appearance',
            name: 'appearance_settings',
            builder: (context, state) => const AppearanceSettingsPage(),
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
            routes: [
              GoRoute(
                path: 'new',
                name: 'add_patient',
                builder: (context, state) => const AddPatientPage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit_patient',
                builder: (context, state) {
                  final patient = state.extra as PatientModel;
                  return AddPatientPage(patient: patient);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/sessions',
            name: 'sessions',
            builder: (context, state) => const SessionsPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'add_session',
                builder: (context, state) => const AddSessionPage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit_session',
                builder: (context, state) {
                  final session = state.extra as SessionModel;
                  return AddSessionPage(session: session);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/evaluations',
            name: 'evaluations',
            builder: (context, state) => const EvaluationsPage(),
            routes: [
              GoRoute(
                path: 'new',
                name: 'add_evaluation',
                builder: (context, state) => const AddEvaluationPage(),
              ),
              GoRoute(
                path: 'edit',
                name: 'edit_evaluation',
                builder: (context, state) {
                  final evaluation = state.extra as EvaluationModel;
                  return AddEvaluationPage(evaluation: evaluation);
                },
              ),
            ],
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
            routes: [
              GoRoute(
                path: 'create',
                name: 'create_clinical_report',
                builder: (context, state) => const CreateClinicalReportPage(),
              ),
              GoRoute(
                path: 'new',
                name: 'add_clinical_report',
                builder: (context, state) {
                  final patientId = state.uri.queryParameters['patientId'];
                  return AddEditClinicalReportPage(patientId: patientId);
                },
              ),
              GoRoute(
                path: 'clinical_report_details/:reportId',
                name: 'clinical_report_details',
                builder: (context, state) {
                  final reportId = state.pathParameters['reportId']!;
                  return ClinicalReportDetailsPage(reportId: reportId);
                },
              ),
              GoRoute(
                path: ':reportId/edit',
                name: 'edit_clinical_report',
                builder: (context, state) {
                  final reportId = state.pathParameters['reportId']!;
                  return AddEditClinicalReportPage(reportId: reportId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/chatgpt_project',
            name: 'chatgpt_project',
            builder: (context, state) => const ChatGptProjectListPage(),
          ),
          GoRoute(
            path: '/settings/api_key',
            name: 'api_key_settings',
            builder: (context, state) {
              final from = state.uri.queryParameters['from'];
              return ApiKeySettingsPage(from: from);
            },
          ),
          GoRoute(
            path: '/settings/model_selection',
            name: 'model_selection',
            builder: (context, state) => const ModelSelectionPage(),
          ),
          GoRoute(
            path: '/settings/export_data',
            name: 'export_data',
            builder: (context, state) => const ExportDataPage(),
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
          GoRoute(
            path: '/staff/add',
            name: 'add_staff',
            builder: (context, state) => const AddEditStaffPage(),
          ),
          GoRoute(
            path: '/staff/:staffId',
            name: 'edit_staff',
            builder: (context, state) {
              final staffId = state.pathParameters['staffId'];
              return AddEditStaffPage(staffId: staffId);
            },
          ),
          GoRoute(
            path: '/invitations',
            name: 'invitations',
            builder: (context, state) {
              return FutureBuilder<UserModel?>(
                future: sl<AuthUseCase>().getCurrentUser(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final clinicId = snapshot.data?.primaryClinicId ?? '';
                  return InvitationsPage(clinicId: clinicId);
                },
              );
            },
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-invitation',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final clinicId = extra['clinicId'] as String;
                  final currentUserId = extra['currentUserId'] as String;

                  return BlocProvider.value(
                    value: sl<InvitationBloc>(),
                    child: CreateInvitationPage(
                      clinicId: clinicId,
                      currentUserId: currentUserId,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/help_support',
            name: 'help_support',
            builder: (context, state) => const HelpSupportPage(),
          ),
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => const AboutPage(),
          ),
          GoRoute(
            path: '/privacy',
            name: 'privacy',
            builder: (context, state) => const PrivacyPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => const AccountPage(),
      ),
      GoRoute(
        path: '/accept-invitation',
        name: 'accept-invitation',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (token == null || token.isEmpty) {
            return const ErrorRoutePage();
          }
          return AcceptInvitationPage(token: token);
        },
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SignupPage(
            invitationToken: extra?['invitationToken'] as String?,
            email: extra?['email'] as String?,
            name: extra?['name'] as String?,
            clinicName: extra?['clinicName'] as String?,
            clinicId: extra?['clinicId'] as String?,
            role: extra?['role'] as String?,
          );
        },
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
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
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
