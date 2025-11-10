import 'package:equatable/equatable.dart';

class ChatGptProjectModel extends Equatable {
  final String id;
  final String name;

  const ChatGptProjectModel({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}
