import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';

abstract class ChatGptProjectRepository {
  Future<ChatGptProject?> getProjectByName(String name);
  Future<ChatGptProject> createProject(String name);
}

