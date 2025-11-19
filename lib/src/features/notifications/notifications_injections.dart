import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/features/notifications/data/remote/abstract_notification_api.dart';
import 'package:dr_copilot/src/features/notifications/data/remote/notification_firebase_api.dart';
import 'package:dr_copilot/src/features/notifications/data/repositories/notifications_repo_impl.dart';
import 'package:dr_copilot/src/features/notifications/domain/repositories/abstract_notifications_repository.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/notifications_usecase.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/send_bulk_notification_usecase.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/send_notification/send_notification_bloc.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the notifications feature.
///
/// This function sets up all necessary services and dependencies related to
/// notifications, ensuring they are available throughout the application.
/// Call this during the application's initialization phase.
void initNotificationsInjections() {
  // BLoC
  sl.registerFactory(() => NotificationsBloc(
        useCase: sl(),
        sendBulkUseCase: sl(),
      ));
  
  sl.registerFactory(() => SendNotificationBloc(
        sendBulkNotificationUseCase: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => NotificationsUseCase(repository: sl()));
  sl.registerLazySingleton(() => SendBulkNotificationUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AbstractNotificationsRepository>(
    () => NotificationsRepositoryImpl(api: sl()),
  );

  // Data source
  sl.registerLazySingleton<AbstractNotificationApi>(
    () => NotificationFirebaseApi(),
  );
}
