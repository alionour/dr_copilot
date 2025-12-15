import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';

abstract class ChatGptProjectListRepository {
  Future<List<ChatGptProject>> getChatGptProjects();
}

