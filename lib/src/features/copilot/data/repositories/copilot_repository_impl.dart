import 'package:dr_copilot/src/features/copilot/data/datasources/copilot_remote_data_source.dart';
import 'package:dr_copilot/src/features/copilot/domain/models/copilot_model.dart';
import 'package:dr_copilot/src/features/copilot/domain/repositories/copilot_repository.dart';

class CopilotRepositoryImpl implements CopilotRepository {
  final CopilotRemoteDataSource _remoteDataSource;

  CopilotRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CopilotModel>> getCopilots() {
    return _remoteDataSource.getCopilots();
  }

  @override
  Future<void> addCopilot(CopilotModel copilot) {
    return _remoteDataSource.addCopilot(copilot);
  }

  @override
  Future<void> updateCopilot(CopilotModel copilot) {
    return _remoteDataSource.updateCopilot(copilot);
  }

  @override
  Future<void> deleteCopilot(String id) {
    return _remoteDataSource.deleteCopilot(id);
  }
}
