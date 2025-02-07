import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/data/repositories/patients_repo_impl.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

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
      ],
      child: MaterialApp.router(
        routerConfig: RoutingConfig.router,
        title: 'Dr Copilot',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
      ),
    );
  }
}
