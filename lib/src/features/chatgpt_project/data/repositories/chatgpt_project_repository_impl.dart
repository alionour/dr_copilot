import 'package:dr_copilot/src/features/chatgpt_project/data/remote/chatgpt_project_remote_data_source.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/models/chatgpt_project_model.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_repository.dart';

class ChatGptProjectRepositoryImpl implements ChatGptProjectRepository {
  final ChatGptProjectRemoteDataSource remoteDataSource;
  final String apiKey;

  ChatGptProjectRepositoryImpl(
      {required this.remoteDataSource, required this.apiKey});

  @override
  Future<ChatGptProjectModel?> getProjectByName(String name) {
    return remoteDataSource.getProjectByName(name, apiKey);
  }

  @override
  Future<ChatGptProjectModel> createProject(String name) {
    return remoteDataSource.createProject(name, apiKey);
  }
}
