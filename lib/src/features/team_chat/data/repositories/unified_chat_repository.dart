import '../models/team_message_model.dart';
import '../repositories/team_chat_repository.dart';
import '../repositories/direct_messages_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified repository that handles both team chats and direct messages
/// Automatically detects conversation type and delegates to correct repository
class UnifiedChatRepository {
  final TeamChatRepository _teamChatRepository;
  final DirectMessagesRepository _directMessagesRepository;
  final FirebaseFirestore _firestore;

  UnifiedChatRepository({
    required TeamChatRepository teamChatRepository,
    required DirectMessagesRepository directMessagesRepository,
    FirebaseFirestore? firestore,
  })  : _teamChatRepository = teamChatRepository,
        _directMessagesRepository = directMessagesRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Detect if conversation is a direct message or team chat
  Future<bool> _isDirectMessage(String conversationId) async {
    // Check if it exists in team_conversations first
    final teamDoc = await _firestore
        .collection('team_conversations')
        .doc(conversationId)
        .get();

    if (teamDoc.exists) {
      // It's a team conversation (could be team chat or 1-on-1)
      // Check metadata to distinguish
      final metadata = teamDoc.data()?['metadata'] as Map<String, dynamic>?;
      // If it has a teamId in metadata, it's a team chat
      // If not, it's a 1-on-1 direct message
      return metadata == null || !metadata.containsKey('teamId');
    }

    // Fallback: check direct_messages collection (if you have one)
    final directDoc = await _firestore
        .collection('direct_messages')
        .doc(conversationId)
        .get();
    return directDoc.exists;
  }

  /// Get messages - delegates to correct repository
  Stream<List<TeamMessageModel>> getMessages(String conversationId) async* {
    final isDirect = await _isDirectMessage(conversationId);
    if (isDirect) {
      yield* _directMessagesRepository.getMessages(conversationId);
    } else {
      yield* _teamChatRepository.getMessages(conversationId);
    }
  }

  /// Send message - delegates to correct repository
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final isDirect = await _isDirectMessage(conversationId);
    if (isDirect) {
      await _directMessagesRepository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        type: type,
      );
    } else {
      await _teamChatRepository.sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        content: content,
        type: type,
      );
    }
  }
}
