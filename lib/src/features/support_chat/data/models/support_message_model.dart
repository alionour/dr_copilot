import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SupportMessageType { text, image, file }

class SupportMessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final SupportMessageType type;
  final DateTime timestamp;
  final List<String> readBy;

  const SupportMessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = SupportMessageType.text,
    required this.timestamp,
    this.readBy = const [],
  });

  factory SupportMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportMessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      type: SupportMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['type'] ?? 'text'),
        orElse: () => SupportMessageType.text,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        type,
        timestamp,
        readBy,
      ];
}
