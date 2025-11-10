import 'package:dr_copilot/src/features/chatgpt_project/domain/models/chatgpt_project_model.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_repository.dart';

class GetOrCreateProject {
  final ChatGptProjectRepository repository;

  GetOrCreateProject(this.repository);

  Future<ChatGptProjectModel> call(String name) async {
    final project = await repository.getProjectByName(name);
    if (project != null) {
      return project;
    } else {
      return await repository.createProject(name);
    }
  }
}
