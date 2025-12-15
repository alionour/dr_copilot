import 'package:get_it/get_it.dart';
import 'data/repositories/team_chat_repository.dart';
import 'data/repositories/direct_messages_repository.dart';
import 'data/repositories/unified_chat_repository.dart';
import 'domain/services/user_discovery_service.dart';
import 'presentation/bloc/team_chat_list_bloc.dart';
import 'presentation/bloc/chat_room_bloc.dart';
import 'presentation/cubit/user_discovery_cubit.dart';

final sl = GetIt.instance;

void initTeamChatInjections() {
  // Repositories & Services
  sl.registerLazySingleton(() => TeamChatRepository());
  sl.registerLazySingleton(() => DirectMessagesRepository());
  sl.registerLazySingleton(
    () => UnifiedChatRepository(
      teamChatRepository: sl(),
      directMessagesRepository: sl(),
    ),
  );
  sl.registerLazySingleton(() => UserDiscoveryService());

  // Blocs & Cubits
  sl.registerFactory(
    () => TeamChatListBloc(
      sl<TeamChatRepository>(),
      sl<DirectMessagesRepository>(),
    ),
  );
  sl.registerFactory(() => ChatRoomBloc(sl()));
  sl.registerFactory(() => UserDiscoveryCubit(sl(), sl()));
}

