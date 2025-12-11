import 'package:get_it/get_it.dart';
import 'data/repositories/support_chat_repository.dart';
import 'presentation/bloc/support_chat_bloc.dart';

final sl = GetIt.instance;

void initSupportChatInjections() {
  // Repository
  sl.registerLazySingleton<SupportChatRepository>(
    () => SupportChatRepository(),
  );

  // BLoC
  sl.registerFactory<SupportChatBloc>(() => SupportChatBloc(repository: sl()));
}
