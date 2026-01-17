import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ConversationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ConversationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Generate smart title from message
  String _generateTitle(String message) {
    // Remove common words and clean up
    final words = message.trim().split(' ');
    final stopWords = {
      'the',
      'a',
      'an',
      'is',
      'are',
      'was',
      'were',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'and',
      'or',
      'but',
      'can',
      'you',
      'how',
      'what',
      'when',
      'where',
      'why'
    };

    final meaningfulWords = words
        .where((word) =>
            word.length > 2 && !stopWords.contains(word.toLowerCase()))
        .take(6)
        .join(' ');

    String title = meaningfulWords.isNotEmpty ? meaningfulWords : message;

    // Truncate if too long
    if (title.length > 40) {
      title = '${title.substring(0, 40)}...';
    }

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    return title.isNotEmpty ? title : 'New Chat';
  }

  // Create a new conversation with an initial message
  Future<String> createConversation({
    required String title,
    required String initialMessageText,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Create conversation document with auto-generated title
    final conversationRef = _firestore.collection('conversations').doc();
    final conversation = ConversationModel(
      id: conversationRef.id,
      userId: _currentUserId!,
      title: _generateTitle(initialMessageText), // Auto-generate smart title
      createdAt: now,
      updatedAt: now,
      lastMessageSnippet: initialMessageText.length > 50
          ? '${initialMessageText.substring(0, 50)}...'
          : initialMessageText,
    );

    batch.set(conversationRef, conversation.toFirestore());

    // Create initial message in a subcollection
    final messageRef = conversationRef.collection('messages').doc();
    final message = MessageModel(
      id: messageRef.id,
      userId: _currentUserId!,
      senderId: _currentUserId!,
      text: initialMessageText,
      timestamp: now,
      type: 'text',
    );

    batch.set(messageRef, message.toFirestore());

    await batch.commit();
    return conversationRef.id;
  }

  // Add a message to an existing conversation
  Future<void> addMessage({
    required String conversationId,
    required String text,
    required String senderId,
    String type = 'text',
    String? audioUrl,
    int? audioDuration,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final batch = _firestore.batch();

    final conversationDocRef =
        _firestore.collection('conversations').doc(conversationId);

    // Add message to subcollection
    final messageRef = conversationDocRef.collection('messages').doc();
    final message = MessageModel(
      id: messageRef.id,
      userId: _currentUserId!,
      senderId: senderId,
      text: text,
      timestamp: now,
      type: type,
      audioUrl: audioUrl,
      audioDuration: audioDuration,
    );

    batch.set(messageRef, message.toFirestore());

    // Update conversation
    batch.update(conversationDocRef, {
      'updatedAt': Timestamp.fromDate(now),
      'lastMessageSnippet':
          text.length > 50 ? '${text.substring(0, 50)}...' : text,
    });

    await batch.commit();
  }

  // Update a message in a conversation
  Future<void> updateMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({
      'text': newText,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a specific message
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Get conversations for current user with pagination
  Stream<List<ConversationModel>> getConversations({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    // Temporary: Client-side sorting (no index required)
    // Once Firestore index is ready, uncomment .orderBy line below
    Query query = _firestore
        .collection('conversations')
        .where('userId', isEqualTo: _currentUserId)
        // .orderBy('updatedAt', descending: true) // REQUIRES INDEX - commented out temporarily
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ConversationModel.fromFirestore(doc))
          .toList();

      // Sort client-side instead (temporary workaround)
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return conversations;
    });
  }

  // Get messages for a conversation with pagination
  Stream<List<MessageModel>> getMessages({
    required String conversationId,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    final conversationDocRef =
        _firestore.collection('conversations').doc(conversationId);
    Query query = conversationDocRef
        .collection('messages')
        .orderBy('timestamp', descending: true) // Fetch newest first
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Fetch messages for pagination (Future-based)
  Future<List<MessageModel>> fetchMessages({
    required String conversationId,
    int limit = 20,
    dynamic lastTimestamp,
  }) async {
    if (_currentUserId == null) {
      return [];
    }

    final conversationDocRef =
        _firestore.collection('conversations').doc(conversationId);
    Query query = conversationDocRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (lastTimestamp != null) {
      query = query.startAfter([lastTimestamp]);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
  }

  // Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    // Delete conversation
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);
    batch.delete(conversationRef);

    // Delete all messages in this conversation's subcollection
    final messagesSnapshot = await conversationRef.collection('messages').get();

    for (var doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Rename a conversation
  Future<void> renameConversation({
    required String conversationId,
    required String newTitle,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'title': newTitle.trim(),
      'updatedAt': DateTime.now(),
    });
  }

  // Update conversation title
  Future<void> updateConversationTitle({
    required String conversationId,
    required String newTitle,
  }) async {
    if (_currentUserId == null) throw Exception('User not authenticated');

    await _firestore.collection('conversations').doc(conversationId).update({
      'title': newTitle,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
