import 'package:dr_copilot/src/features/copilot_chat/domain/models/copilot_model.dart';

abstract class CopilotRepository {
  Future<List<CopilotModel>> getCopilots();
  Future<void> addCopilot(CopilotModel copilot);
  Future<void> updateCopilot(CopilotModel copilot);
  Future<void> deleteCopilot(String id);
}
