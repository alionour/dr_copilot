import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/inventory/data/remote/inventory_firebase_api.dart';
import 'package:dr_copilot/src/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:dr_copilot/src/features/inventory/domain/repositories/abstract_inventory_repository.dart';
import 'package:dr_copilot/src/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:dr_copilot/src/features/inventory/presentation/bloc/inventory_bloc.dart';

/// Initializes dependency injections for inventory feature
void initInventoryInjections() {
  // Data Layer - Firebase API
  sl.registerLazySingleton<InventoryFirebaseApi>(
    () => InventoryFirebaseApi(),
  );

  // Data Layer - Repository
  sl.registerLazySingleton<AbstractInventoryRepository>(
    () => InventoryRepositoryImpl(sl()),
  );

  // Domain Layer - Use Case
  sl.registerLazySingleton<InventoryUseCase>(
    () => InventoryUseCase(sl()),
  );

  // Presentation Layer - BLoC
  sl.registerFactory<InventoryBloc>(() => InventoryBloc(sl()));
}
