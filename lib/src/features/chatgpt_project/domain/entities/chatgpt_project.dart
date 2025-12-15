import 'package:equatable/equatable.dart';

class ChatGptProject extends Equatable {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatGptProject({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, description, createdAt, updatedAt];
}

