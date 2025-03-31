import 'package:dr_copilot/firebase_options.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot/services/vertex_ai_service.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_api_impl.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/repositories/evaluations_repository_impl.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_api_impl.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/repositories/sessions_repository_impl.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/core/helper/api_key_helper.dart';
import 'src/core/router/routing_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initInjections();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(isDarkMode: isDarkMode),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (context) => AuthBloc(),
            ),
            BlocProvider<NavigationBloc>(
                create: (context) => NavigationBloc()..add(GetUserData())),
            BlocProvider<PatientsBloc>(
                create: (context) => PatientsBloc(
                      PatientsUseCase(
                        PatientsRepositoryImpl(
                          PatientFirebaseApi(),
                        ),
                      ),
                    )),
            BlocProvider<CopilotBloc>(
              create: (context) => CopilotBloc(
                vertexAIService: VertexAIService(ApiKeyHelper.vertexAIKey),
                gptService: GPTService(ApiKeyHelper.gptKey),
                geminiService: GeminiService(ApiKeyHelper.geminiKey),
                deepSeekService: DeepSeekService(ApiKeyHelper.deepSeekKey),
                qwenService: QwenService(ApiKeyHelper.qwenKey),
                claudeService: ClaudeService(ApiKeyHelper.claudeKey),
              ),
            ),
            BlocProvider<SettingsBloc>(
              create: (context) => SettingsBloc(),
            ),
            BlocProvider<SessionsBloc>(
              create: (context) => SessionsBloc(
                SessionsUseCase(
                  SessionsRepositoryImpl(
                    firebaseApi: SessionFirebaseApi(),
                  ),
                ),
              ),
            ),
            BlocProvider<EvaluationsBloc>(
              create: (context) => EvaluationsBloc(
                EvaluationsUseCase(
                  EvaluationsRepositoryImpl(
                    firebaseApi: EvaluationFirebaseApi(),
                  ),
                ),
              ),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: RoutingConfig.router,
            title: 'Dr Copilot',
            theme: themeNotifier.currentTheme,
            debugShowCheckedModeBanner: false,
          ),
        );
      },
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode;

  ThemeNotifier({required bool isDarkMode}) : _isDarkMode = isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme {
    return _isDarkMode
        ? FlexColorScheme.dark(scheme: FlexScheme.mandyRed).toTheme
        : FlexColorScheme.light(scheme: FlexScheme.mandyRed).toTheme;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
