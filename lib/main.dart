import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot/services/vertex_ai_service.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'firebase_options.dart';
import 'src/core/router/routing_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initInjections();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
            vertexAIService: VertexAIService('YOUR_VERTEX_AI_API_KEY'),
            gptService: GPTService(
                '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'),
            geminiService:
                GeminiService('AIzaSyDgfy1uZ7DdP0DJK69XnLZnZ_kncV_U2ms'),
          ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: RoutingConfig.router,
        title: 'Dr Copilot',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.accents.first),
          useMaterial3: true,
        ),
      ),
    );
  }
}
