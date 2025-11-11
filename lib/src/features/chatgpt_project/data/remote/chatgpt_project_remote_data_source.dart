import 'dart:convert';
import 'package:dr_copilot/src/features/chatgpt_project/domain/models/chatgpt_project_model.dart';
import 'package:http/http.dart' as http;

abstract class ChatGptProjectRemoteDataSource {
  Future<ChatGptProjectModel?> getProjectByName(String name, String apiKey);
  Future<ChatGptProjectModel> createProject(String name, String apiKey);
}

class ChatGptProjectRemoteDataSourceImpl
    implements ChatGptProjectRemoteDataSource {
  final http.Client client;

  ChatGptProjectRemoteDataSourceImpl({required this.client});

  @override
  Future<ChatGptProjectModel?> getProjectByName(
      String name, String apiKey) async {
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
      for (final assistant in assistants) {
        if (assistant['name'] == name) {
          return ChatGptProjectModel(
              id: assistant['id'], name: assistant['name']);
        }
      }
      return null;
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
      return ChatGptProjectModel(id: data['id'], name: data['name']);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Failed to create project: ${errorData['error']['message']}');
    }
  }
}
