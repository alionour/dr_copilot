import 'package:dr_copilot/src/features/chatgpt_project/data/models/chatgpt_project_model.dart';

abstract class ChatGptProjectListDatasource {
  Future<List<ChatGptProjectModel>> getChatGptProjects();
}

class ChatGptProjectListDatasourceImpl implements ChatGptProjectListDatasource {
  @override
  Future<List<ChatGptProjectModel>> getChatGptProjects() async {
    // TODO: Implement actual data fetching from an API or local storage
    // For now, return mock data
    return Future.value([
      ChatGptProjectModel(
        id: '1',
        name: 'Project Alpha',
        description:
            'A project to develop an AI assistant for medical diagnosis.',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ChatGptProjectModel(
        id: '2',
        name: 'Project Beta',
        description:
            'Research on natural language processing for patient records.',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ]);
  }
}
