import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TeamConversationModel extends Equatable {
  final String id;
  final String clinicId;
  final List<String> participantIds;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>
  metadata; // For things like "typing" status or "unread" counts per user

  const TeamConversationModel({
    required this.id,
    required this.clinicId,
    required this.participantIds,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory TeamConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamConversationModel(
      id: doc.id,
      clinicId: data['clinicId'] ?? '',
      participantIds: List<String>.from(data['participantIds'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTimestamp: (data['lastMessageTimestamp'] as Timestamp?)
          ?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clinicId': clinicId,
      'participantIds': participantIds,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp != null
          ? Timestamp.fromDate(lastMessageTimestamp!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    clinicId,
    participantIds,
    lastMessage,
    lastMessageTimestamp,
    createdAt,
    updatedAt,
    metadata,
  ];
}

