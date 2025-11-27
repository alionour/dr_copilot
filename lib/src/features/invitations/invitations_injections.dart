import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/features/invitations/data/remote/invitation_firebase_api.dart';
import 'package:dr_copilot/src/features/invitations/data/repositories/invitation_repository_impl.dart';
import 'package:dr_copilot/src/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:dr_copilot/src/features/invitations/domain/usecases/invitation_usecases.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';

final sl = GetIt.instance;

void initInvitationsInjections() {
  // BLoC
  sl.registerFactory(() => InvitationBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => InvitationUseCases(sl()));

  // Repository
  sl.registerLazySingleton<InvitationRepository>(
    () => InvitationRepositoryImpl(sl()),
  );

  // Data source
  sl.registerLazySingleton(() => InvitationFirebaseApi());
}
