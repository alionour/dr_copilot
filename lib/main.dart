import 'package:dr_copilot/navigation/bloc/navigation_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'routing/routing_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://towoeiooghmluwgtmnej.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRvd29laW9vZ2htbHV3Z3RtbmVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzczMTEyODgsImV4cCI6MjA1Mjg4NzI4OH0.KiamFMjsATNlQmWNg_V-dkzpKAe5AiU0fQLNf6wgpLM',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationBloc>(
          create: (context) => NavigationBloc()..add(GetUserData()),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        title: 'Dr Copilot',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
      ),
    );
  }
}
