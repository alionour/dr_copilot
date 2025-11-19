import 'package:collection/collection.dart';
import 'package:dr_copilot/src/features/chatgpt_project/data/remote/chatgpt_project_remote_data_source.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_repository.dart';

class ChatGptProjectRepositoryImpl implements ChatGptProjectRepository {
  final ChatGptProjectRemoteDataSource remoteDataSource;
  final String apiKey;

  ChatGptProjectRepositoryImpl(
      {required this.remoteDataSource, required this.apiKey});

  @override
  Future<ChatGptProject?> getProjectByName(String name) async {
    final projects = await remoteDataSource.getProjects(apiKey);
    return projects.firstWhereOrNull((project) => project.name == name);
  }

  @override
  Future<ChatGptProject> createProject(String name) {
    return remoteDataSource.createProject(name, apiKey);
  }
}
