import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a direct message conversation between two users
class DirectConversationModel extends Equatable {
  final String id;
  final String clinicId;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;

  const DirectConversationModel({
    required this.id,
    required this.clinicId,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory DirectConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DirectConversationModel(
      id: doc.id,
      clinicId: data['clinicId'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp?)
          ?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clinicId': clinicId,
      'participantIds': participantIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTimestamp != null)
        'lastMessageTimestamp': Timestamp.fromDate(lastMessageTimestamp!),
    };
  }

  @override
  List<Object?> get props => [
    id,
    clinicId,
    participantIds,
    createdAt,
    updatedAt,
    lastMessage,
    lastMessageTimestamp,
  ];
}
