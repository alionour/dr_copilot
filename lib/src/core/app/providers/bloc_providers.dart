import 'package:dr_copilot/src/features/appointments/sessions/data/remote/Session_firebase_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import '../../../features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import '../../../features/appointments/evaluations/data/repositories/evaluations_repository_impl.dart';
import '../../../features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import '../../../features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import '../../../features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import '../../../features/appointments/sessions/data/repositories/sessions_repository_impl.dart';
import '../../../features/appointments/sessions/data/remote/session_firebase_api.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/copilot/presentation/bloc/copilot_bloc.dart';
import '../../../features/copilot/services/claude_service.dart';
import '../../../features/copilot/services/deepseek_service.dart';
import '../../../features/copilot/services/gemini_service.dart';
import '../../../features/copilot/services/gpt_service.dart';
import '../../../features/copilot/services/qwen_service.dart';
import '../../../features/copilot/services/vertex_ai_service.dart';
import '../../../features/financials/presentation/bloc/financials_bloc.dart';
import '../../../features/financials/domain/usecases/financials_usecase.dart';
import '../../../features/financials/data/repositories/financials_repository_impl.dart';
import '../../../features/financials/data/remote/financials_firebase_api.dart';
import '../../../features/navigation_side/presentation/bloc/navigation_bloc.dart';
import '../../../features/patients/presentation/bloc/patients_bloc.dart';
import '../../../features/patients/domain/usecases/patients_usecase.dart';
import '../../../features/patients/data/repositories/patients_repo_impl.dart';
import '../../../features/patients/data/remote/patient_firebase_api.dart';
import '../../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../helper/api_key_helper.dart';

final appBlocProviders = <BlocProvider<dynamic>>[
  BlocProvider<AuthBloc>(create: (context) => AuthBloc()),
  BlocProvider<NavigationBloc>(create: (context) => NavigationBloc()..add(GetUserData())),
  BlocProvider<PatientsBloc>(create: (context) => PatientsBloc(
    PatientsUseCase(PatientsRepositoryImpl(PatientFirebaseApi())),
  )),
  BlocProvider<CopilotBloc>(create: (context) => CopilotBloc(
    vertexAIService: VertexAIService(ApiKeyHelper.vertexAIKey),
    gptService: GPTService(ApiKeyHelper.gptKey),
    geminiService: GeminiService(ApiKeyHelper.geminiKey),
    deepSeekService: DeepSeekService(ApiKeyHelper.deepSeekKey),
    qwenService: QwenService(ApiKeyHelper.qwenKey),
    claudeService: ClaudeService(ApiKeyHelper.claudeKey),
  )),
  BlocProvider<SettingsBloc>(create: (context) => SettingsBloc()),
  BlocProvider<SessionsBloc>(create: (context) => SessionsBloc(
    SessionsUseCase(SessionsRepositoryImpl( SessionsFirebaseApi())),
  )),
  BlocProvider<EvaluationsBloc>(create: (context) => EvaluationsBloc(
    EvaluationsUseCase(EvaluationsRepositoryImpl( EvaluationsFirebaseApi())),
  )),
  BlocProvider<FinancialsBloc>(create: (context) => FinancialsBloc(
  FinancialsUseCase(FinancialsRepositoryImpl( FinancialsFirebaseApi())),
  )),
];
