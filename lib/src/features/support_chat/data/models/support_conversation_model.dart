import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SupportConversationStatus { open, closed }

class SupportConversationModel extends Equatable {
  final String id;
  final String userId;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SupportConversationStatus status;

  const SupportConversationModel({
    required this.id,
    required this.userId,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.createdAt,
    required this.updatedAt,
    this.status = SupportConversationStatus.open,
  });

  factory SupportConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportConversationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp?)
          ?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SupportConversationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'open'),
        orElse: () => SupportConversationStatus.open,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status.toString().split('.').last,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    lastMessage,
    lastMessageTimestamp,
    createdAt,
    updatedAt,
    status,
  ];
}
