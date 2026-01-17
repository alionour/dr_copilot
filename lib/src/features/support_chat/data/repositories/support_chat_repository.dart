import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_conversation_model.dart';
import '../models/support_message_model.dart';

class SupportChatRepository {
  final FirebaseFirestore _firestore;

  SupportChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get or create a support conversation for a user
  Future<String> getOrCreateConversation(String userId) async {
    // Check if conversation already exists
    final querySnapshot = await _firestore
        .collection('support_conversations')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.id;
    }

    // Create new conversation
    final now = DateTime.now();
    final newConversationRef =
        _firestore.collection('support_conversations').doc();

    final newConversation = SupportConversationModel(
      id: newConversationRef.id,
      userId: userId,
      createdAt: now,
      updatedAt: now,
      status: SupportConversationStatus.open,
    );

    await newConversationRef.set(newConversation.toFirestore());
    return newConversationRef.id;
  }

  /// Get messages for a support conversation
  Stream<List<SupportMessageModel>> getMessages(String conversationId,
      {int limit = 50}) {
    return _firestore
        .collection('support_conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a message in support conversation
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    SupportMessageType type = SupportMessageType.text,
  }) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // 1. Create message document
    final messageRef = _firestore
        .collection('support_conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = SupportMessageModel(
      id: messageRef.id,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      timestamp: now,
      readBy: [senderId],
    );

    batch.set(messageRef, message.toFirestore());

    // 2. Update conversation last message details
    final conversationRef =
        _firestore.collection('support_conversations').doc(conversationId);

    batch.update(conversationRef, {
      'lastMessage': type == SupportMessageType.text ? content : '[Image]',
      'lastMessageTimestamp': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    await batch.commit();
  }

  /// Get conversation details
  Future<SupportConversationModel?> getConversation(
    String conversationId,
  ) async {
    final doc = await _firestore
        .collection('support_conversations')
        .doc(conversationId)
        .get();

    if (!doc.exists) return null;
    return SupportConversationModel.fromFirestore(doc);
  }
}
