import 'package:dr_copilot/src/features/chatgpt_project/data/datasources/chatgpt_project_list_datasource.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/repositories/chatgpt_project_list_repository.dart';

class ChatGptProjectListRepositoryImpl implements ChatGptProjectListRepository {
  final ChatGptProjectListDatasource datasource;

  ChatGptProjectListRepositoryImpl({required this.datasource});

  @override
  Future<List<ChatGptProject>> getChatGptProjects() async {
    final models = await datasource.getChatGptProjects();
    return models.map((model) => model as ChatGptProject).toList();
  }
}

