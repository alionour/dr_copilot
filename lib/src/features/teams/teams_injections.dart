import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/teams/data/repositories/custom_teams_repository_impl.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_bloc.dart';

void initTeamsInjections() {
  // Blocs
  sl.registerFactory(() => TeamsBloc(repository: sl()));

  // Repositories
  sl.registerLazySingleton<AbstractCustomTeamsRepository>(
    () => CustomTeamsRepositoryImpl(),
  );
}
