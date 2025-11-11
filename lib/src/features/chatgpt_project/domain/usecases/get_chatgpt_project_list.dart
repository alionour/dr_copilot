import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_list_repository.dart';

class GetChatGptProjectList {
  final ChatGptProjectListRepository repository;

  GetChatGptProjectList(this.repository);

  Future<List<ChatGptProject>> call() {
    return repository.getChatGptProjects();
  }
}
