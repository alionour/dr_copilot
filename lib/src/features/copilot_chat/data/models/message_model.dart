import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String userId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final DateTime? updatedAt;
  final String type;
  final String? audioUrl;
  final int? audioDuration;

  MessageModel({
    required this.id,
    required this.userId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.updatedAt,
    this.type = 'text',
    this.audioUrl,
    this.audioDuration,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      userId: data['userId'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] == null ? null : (data['updatedAt'] as Timestamp).toDate(),
      type: data['type'] as String? ?? 'text',
      audioUrl: data['audioUrl'] as String?,
      audioDuration: data['audioDuration'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'type': type,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
    };
  }

  bool get isUser => senderId == userId;
}

