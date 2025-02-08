import 'package:dr_copilot/src/features/copilot/domain/models/copilot_model.dart';
import 'package:dr_copilot/src/features/copilot/domain/repositories/copilot_repository.dart';

class CopilotUseCase {
  final CopilotRepository _repository;

  CopilotUseCase(this._repository);

  Future<List<CopilotModel>> getCopilots() {
    return _repository.getCopilots();
  }

  Future<void> addCopilot(CopilotModel copilot) {
    return _repository.addCopilot(copilot);
  }

  Future<void> updateCopilot(CopilotModel copilot) {
    return _repository.updateCopilot(copilot);
  }

  Future<void> deleteCopilot(String id) {
    return _repository.deleteCopilot(id);
  }
}
