import 'package:cloud_firestore/cloud_firestore.dart';

// MarketplaceMessage model is unchanged and correct.
class MarketplaceMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;

  MarketplaceMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

class MarketplaceChatService {
  // --- THIS IS THE FIX ---
  // The unused '_firestore' variable has been removed. We only need the direct
  // reference to the 'marketplace_chats' collection.
  final CollectionReference _chatsCollection = FirebaseFirestore.instance
      .collection('marketplace_chats');
  // --- END OF FIX ---

  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  /// Sends a message and updates the main chat document for the chat list.
  Future<void> sendMessage(
    String chatRoomId,
    String text,
    String senderId,
    String receiverId,
  ) async {
    if (text.trim().isEmpty) return;

    final Timestamp timestamp = Timestamp.now();

    MarketplaceMessage newMessage = MarketplaceMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: timestamp,
    );

    // 1. Add the new message to the 'messages' subcollection
    await _chatsCollection
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());

    // 2. Update the main chat document for the chat list screen
    await _chatsCollection.doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'lastMessageTimestamp': timestamp,
    }, SetOptions(merge: true));
  }

  /// Gets a real-time stream of messages for a specific chat room.
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _chatsCollection
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Gets a real-time stream of all chat rooms a user is a part of.
  Stream<QuerySnapshot> getChatList(String userId) {
    return _chatsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
}
