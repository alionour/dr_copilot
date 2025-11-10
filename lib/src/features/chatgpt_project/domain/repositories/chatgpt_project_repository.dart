import 'package:dr_copilot/src/features/chatgpt_project/domain/models/chatgpt_project_model.dart';

abstract class ChatGptProjectRepository {
  Future<ChatGptProjectModel?> getProjectByName(String name);
  Future<ChatGptProjectModel> createProject(String name);
}
