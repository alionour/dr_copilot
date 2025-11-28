import 'package:equatable/equatable.dart';

enum ChatMessageSender { user, ai }

class ClinicalReportChatMessage extends Equatable {
  final String id;
  final ChatMessageSender sender;
  final String text;
  final DateTime timestamp;

  const ClinicalReportChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory ClinicalReportChatMessage.fromJson(Map<String, dynamic> json) {
    return ClinicalReportChatMessage(
      id: json['id'] as String,
      sender: ChatMessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
        orElse: () => ChatMessageSender.user,
      ),
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.name,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, sender, text, timestamp];
}
