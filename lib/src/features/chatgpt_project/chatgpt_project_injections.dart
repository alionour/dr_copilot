import 'package:dr_copilot/src/features/chatgpt_project/data/remote/chatgpt_project_remote_data_source.dart';
import 'package:dr_copilot/src/features/chatgpt_project/data/repositories/chatgpt_project_repository_impl.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_repository.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/usecases/get_or_create_project.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

final sl = GetIt.instance;

void initChatGptProjectInjections() {
  // BLoC
  sl.registerFactory(() => ChatGptProjectBloc(getOrCreateProject: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetOrCreateProject(sl()));

  // Repository
  sl.registerLazySingleton<ChatGptProjectRepository>(
    () => ChatGptProjectRepositoryImpl(
      remoteDataSource: sl(),
      apiKey: '', // TODO: Add your API key here
    ),
  );

  // Remote data source
  sl.registerLazySingleton<ChatGptProjectRemoteDataSource>(
    () => ChatGptProjectRemoteDataSourceImpl(client: sl()),
  );

  // External
  sl.registerLazySingleton(() => http.Client());
}
