import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'data/repositories/charts_repository_impl.dart';
import 'domain/repositories/charts_repository.dart';
import 'presentation/bloc/charts_bloc.dart';

final sl = GetIt.instance;

void initChartsInjections() {
  // Repository
  sl.registerLazySingleton<ChartsRepository>(
    () => ChartsRepositoryImpl(
      firestore: FirebaseFirestore.instance,
    ),
  );

  // BLoC
  sl.registerFactory(
    () => ChartsBloc(
      repository: sl<ChartsRepository>(),
    ),
  );
}
