import 'dart:convert';
import 'package:dr_copilot/src/features/chatgpt_project/data/models/chatgpt_project_model.dart';

import 'package:http/http.dart' as http;

abstract class ChatGptProjectRemoteDataSource {
  Future<List<ChatGptProjectModel>> getProjects(String apiKey);
  Future<ChatGptProjectModel> createProject(String name, String apiKey);
}

class ChatGptProjectRemoteDataSourceImpl
    implements ChatGptProjectRemoteDataSource {
  final http.Client client;

  ChatGptProjectRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ChatGptProjectModel>> getProjects(String apiKey) async {
    final url = Uri.parse('https://api.openai.com/v1/assistants');
    final response = await client.get(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final assistants = data['data'] as List;
      return assistants
          .map((assistant) => ChatGptProjectModel(
                id: assistant['id'],
                name: assistant['name'],
                description: assistant['description'] ?? '',
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                    assistant['created_at'] * 1000),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    assistant['updated_at'] * 1000),
              ))
          .toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to get projects: ${errorData['error']['message']}');
    }
  }

  @override
  Future<ChatGptProjectModel> createProject(String name, String apiKey) async {
    final url = Uri.parse('https://api.openai.com/v1/assistants');
    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'OpenAI-Beta': 'assistants=v2',
      },
      body: jsonEncode({
        'name': name,
        'instructions': 'You are a helpful assistant for a clinic named $name.',
        'model': 'gpt-4',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ChatGptProjectModel(
        id: data['id'],
        name: data['name'],
        description: data['description'] ?? '',
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(data['created_at'] * 1000),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(data['updated_at'] * 1000),
      );
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to create project: ${errorData['error']['message']}');
    }
  }
}
