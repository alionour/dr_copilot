import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/direct_conversation_model.dart';
import '../models/team_message_model.dart';

/// Repository for managing direct message conversations (1-on-1 chats)
class DirectMessagesRepository {
  final FirebaseFirestore _firestore;

  DirectMessagesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all direct conversations for a user
  Stream<List<DirectConversationModel>> getDirectConversations(String userId,
      {int limit = 50}) {
    return _firestore
        .collection('direct_messages')
        .where('participantIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DirectConversationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get messages for a direct conversation
  Stream<List<TeamMessageModel>> getMessages(String conversationId,
      {int limit = 50}) {
    return _firestore
        .collection('direct_messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TeamMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a message in a direct conversation
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // 1. Create message document
    final messageRef = _firestore
        .collection('direct_messages')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = TeamMessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      timestamp: now,
      readBy: [senderId],
    );

    batch.set(messageRef, message.toFirestore());

    // 2. Update conversation metadata
    final conversationRef =
        _firestore.collection('direct_messages').doc(conversationId);

    batch.update(conversationRef, {
      'lastMessage': type == MessageType.text ? content : '[Image]',
      'lastMessageTimestamp': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Start a new direct chat or return existing one
  Future<String> startDirectChat({
    required String clinicId,
    required String currentUserId,
    required String targetUserId,
  }) async {
    // 1. Check if direct chat already exists
    final querySnapshot = await _firestore
        .collection('direct_messages')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      // Filter by clinicId locally to avoid composite index requirement
      if (data['clinicId'] != clinicId) continue;

      final participants = List<String>.from(
        data['participantIds'] ?? [],
      );
      if (participants.contains(targetUserId) && participants.length == 2) {
        return doc.id; // Found existing chat
      }
    }

    // 2. Create new direct chat
    final now = DateTime.now();
    final newChatRef = _firestore.collection('direct_messages').doc();

    final newChat = DirectConversationModel(
      id: newChatRef.id,
      clinicId: clinicId,
      participantIds: [currentUserId, targetUserId],
      createdAt: now,
      updatedAt: now,
    );

    await newChatRef.set(newChat.toFirestore());
    return newChatRef.id;
  }
}
