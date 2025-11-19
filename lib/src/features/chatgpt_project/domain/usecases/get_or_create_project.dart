import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_repository.dart';

class GetOrCreateProject {
  final ChatGptProjectRepository repository;

  GetOrCreateProject(this.repository);

  Future<ChatGptProject> call(String name) async {
    final project = await repository.getProjectByName(name);
    if (project != null) {
      return project;
    } else {
      return await repository.createProject(name);
    }
  }
}
