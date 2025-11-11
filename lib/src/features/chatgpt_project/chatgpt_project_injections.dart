import 'package:dr_copilot/src/features/chatgpt_project/data/remote/chatgpt_project_remote_data_source.dart';
import 'package:dr_copilot/src/features/chatgpt_project/data/repositories/chatgpt_project_repository_impl.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_repository.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/usecases/get_or_create_project.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_bloc.dart';
import 'package:dr_copilot/src/features/chatgpt_project/data/datasources/chatgpt_project_list_datasource.dart';
import 'package:dr_copilot/src/features/chatgpt_project/data/repositories/chatgpt_project_list_repository_impl.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_list_repository.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/usecases/get_chatgpt_project_list.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_list_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final sl = GetIt.instance;

Future<void> initChatGptProjectInjections() async {
  final secureStorage = sl<FlutterSecureStorage>();
  final chatGptApiKey = await secureStorage.read(key: 'chatGptApiKey') ?? '';

  // BLoC
  sl.registerFactory(() => ChatGptProjectBloc(getOrCreateProject: sl()));
  sl.registerFactory(() => ChatGptProjectListBloc(sl(), sl()));

  // Use cases
  sl.registerLazySingleton(() => GetOrCreateProject(sl()));
  sl.registerLazySingleton(() => GetChatGptProjectList(sl()));

  // Repository
  sl.registerLazySingleton<ChatGptProjectRepository>(
    () => ChatGptProjectRepositoryImpl(
      remoteDataSource: sl(),
      apiKey: chatGptApiKey,
    ),
  );
  sl.registerLazySingleton<ChatGptProjectListRepository>(
    () => ChatGptProjectListRepositoryImpl(datasource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ChatGptProjectRemoteDataSource>(
    () => ChatGptProjectRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<ChatGptProjectListDatasource>(
    () => ChatGptProjectListDatasourceImpl(
      remoteDataSource: sl(),
      apiKey: chatGptApiKey,
    ),
  );

  // External
  sl.registerLazySingleton(() => http.Client());
}
