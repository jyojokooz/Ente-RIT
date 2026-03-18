import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ai_chat_message.dart';

class AiConversation {
  final String id;
  final String title;
  final Timestamp timestamp;

  AiConversation({
    required this.id,
    required this.title,
    required this.timestamp,
  });

  factory AiConversation.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AiConversation(
      id: doc.id,
      title: data['title'] ?? 'New Chat',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class ChatAiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _conversationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('ai_conversations');
  }

  // Get a stream of all conversations for a user
  Stream<List<AiConversation>> getConversationsStream(String userId) {
    return _conversationsRef(
      userId,
    ).orderBy('timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AiConversation.fromSnapshot(doc))
          .toList();
    });
  }

  // Get a stream of messages for a specific conversation
  Stream<List<AiChatMessage>> getMessagesStream(
    String userId,
    String conversationId,
  ) {
    return _conversationsRef(userId)
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => AiChatMessage.fromMap(doc.data()))
              .toList();
        });
  }

  // Add a new message to a conversation
  Future<DocumentReference> addMessage(
    String userId,
    String conversationId,
    AiChatMessage message,
  ) async {
    // Also update the conversation's timestamp to bring it to the top of the list
    await _conversationsRef(
      userId,
    ).doc(conversationId).update({'timestamp': Timestamp.now()});

    return await _conversationsRef(
      userId,
    ).doc(conversationId).collection('messages').add(message.toMap());
  }

  // Update a message's content (for streaming AI responses)
  Future<void> updateMessageContent(
    String userId,
    String conversationId,
    String messageId,
    String newContent,
  ) async {
    await _conversationsRef(userId)
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newContent});
  }

  // Create a brand new conversation
  Future<String> createConversation(
    String userId,
    AiChatMessage firstUserMessage,
  ) async {
    final newConversationDoc = await _conversationsRef(userId).add({
      'title':
          firstUserMessage.text.length > 40
              ? '${firstUserMessage.text.substring(0, 40)}...'
              : firstUserMessage.text,
      'timestamp': Timestamp.now(),
    });

    // Add the first message to the new conversation's subcollection
    await newConversationDoc
        .collection('messages')
        .add(firstUserMessage.toMap());

    return newConversationDoc.id;
  }

  // --- NEW METHOD TO DELETE A CONVERSATION AND ITS MESSAGES ---
  Future<void> deleteConversation(String userId, String conversationId) async {
    final conversationDocRef = _conversationsRef(userId).doc(conversationId);

    // 1. Get a reference to the messages subcollection
    final messagesQuery = conversationDocRef.collection('messages');

    // 2. Get all documents from the subcollection
    final messageSnapshots = await messagesQuery.get();

    // 3. Create a batch to delete all messages at once for efficiency
    final batch = _firestore.batch();
    for (var doc in messageSnapshots.docs) {
      batch.delete(doc.reference);
    }
    // Commit the batch delete of messages
    await batch.commit();

    // 4. After the subcollection is empty, delete the parent conversation document
    await conversationDocRef.delete();
  }
}
