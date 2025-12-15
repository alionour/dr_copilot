import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';

class ChatGptProjectModel extends ChatGptProject {
  const ChatGptProjectModel({
    required super.id,
    required super.name,
    required super.description,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatGptProjectModel.fromJson(Map<String, dynamic> json) {
    return ChatGptProjectModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

