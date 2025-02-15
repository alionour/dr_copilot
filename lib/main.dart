import 'package:dr_copilot/firebase_options.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot/services/vertex_ai_service.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/settings/presentation/pages/settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'src/core/helper/api_key_helper.dart';
import 'src/core/router/routing_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initInjections();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeNotifier(),
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
            BlocProvider<NavigationBloc>(
                create: (context) => NavigationBloc()..add(GetUserData())),
            BlocProvider<AuthBloc>(create: (context) => AuthBloc()),
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
          ],
          child: MaterialApp.router(
            routerConfig: RoutingConfig.router,
            title: 'Dr Copilot',
            theme: themeNotifier.currentTheme,
          ),
        );
      },
    );
  }
}
