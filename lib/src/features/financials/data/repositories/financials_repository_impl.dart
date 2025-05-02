import 'package:dr_copilot/src/features/financials/data/remote/financials_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/domain/repositories/abstract_financials_repository.dart';

class FinancialsRepositoryImpl extends AbstractFinancialsRepository {
  final FinancialsFirebaseApi firebaseApi;

  FinancialsRepositoryImpl(this.firebaseApi);

  }
