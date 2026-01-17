import 'package:dr_copilot/src/features/chatgpt_project/data/models/chatgpt_project_model.dart';
import 'package:dr_copilot/src/features/chatgpt_project/data/remote/chatgpt_project_remote_data_source.dart';

abstract class ChatGptProjectListDatasource {
  Future<List<ChatGptProjectModel>> getChatGptProjects();
}

class ChatGptProjectListDatasourceImpl implements ChatGptProjectListDatasource {
  final ChatGptProjectRemoteDataSource remoteDataSource;
  final String apiKey;

  ChatGptProjectListDatasourceImpl({
    required this.remoteDataSource,
    required this.apiKey,
  });

  @override
  Future<List<ChatGptProjectModel>> getChatGptProjects() {
    return remoteDataSource.getProjects(apiKey);
  }
}

