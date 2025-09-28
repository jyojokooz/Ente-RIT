import 'package:cloud_firestore/cloud_firestore.dart';

/// A data model representing a single message in the marketplace chat.
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

  // REMOVED toMap() as it's replaced by toFirestore()

  // --- NEW: Factory constructor to create a message from a Firestore snapshot ---
  factory MarketplaceMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return MarketplaceMessage(
      senderId: data?['senderId'] ?? '',
      receiverId: data?['receiverId'] ?? '',
      text: data?['text'] ?? '',
      timestamp: data?['timestamp'] as Timestamp,
    );
  }

  // --- NEW: Method to convert a message instance to a Map for Firestore ---
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

/// A service class to handle all Firestore chat operations for the marketplace.
class MarketplaceChatService {
  final CollectionReference _chatsCollection = FirebaseFirestore.instance
      .collection('marketplace_chats');

  String getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String text,
    required String senderId,
    required String receiverId,
  }) async {
    if (text.trim().isEmpty) return;

    final newMessage = MarketplaceMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: Timestamp.now(),
    );

    // --- CHANGE: Use .withConverter() to add the typed object directly ---
    await _chatsCollection
        .doc(chatRoomId)
        .collection('messages')
        .withConverter<MarketplaceMessage>(
          fromFirestore: MarketplaceMessage.fromFirestore,
          toFirestore: (message, _) => message.toFirestore(),
        )
        .add(newMessage); // No more .toMap() needed here!

    // Update the main chat document (this part is unchanged)
    await _chatsCollection.doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': text,
      'lastMessageTimestamp': newMessage.timestamp,
    }, SetOptions(merge: true));
  }

  /// Gets a real-time stream of typed [MarketplaceMessage] objects.
  // --- CHANGE: The return type is now cleaner and more specific ---
  Stream<QuerySnapshot<MarketplaceMessage>> getMessages(String chatRoomId) {
    // --- FIX: This is now fully type-safe with NO CAST NEEDED ---
    return _chatsCollection
        .doc(chatRoomId)
        .collection('messages')
        .withConverter<MarketplaceMessage>(
          fromFirestore: MarketplaceMessage.fromFirestore,
          toFirestore: (message, _) => message.toFirestore(),
        )
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Note: getChatList is left as is, because it reads the top-level
  // document which is a simple Map, not a MarketplaceMessage object.
  Stream<QuerySnapshot<Map<String, dynamic>>> getChatList(String userId) {
    return _chatsCollection
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots()
        as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }
}
