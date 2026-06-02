// ===============================
// FILE NAME: marketplace_chat_service.dart
// FILE PATH: lib/services/marketplace_chat_service.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';

/// A data model representing a single message in the marketplace chat.
class MarketplaceMessage {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;

  // --- NEW FIELDS FOR PRODUCT TAGGING ---
  final String? type; // 'text' or 'product'
  final String? productId;
  final String? productTitle;
  final String? productImageUrl;
  final double? productPrice;

  MarketplaceMessage({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.type = 'text',
    this.productId,
    this.productTitle,
    this.productImageUrl,
    this.productPrice,
  });

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
      type: data?['type'] ?? 'text',
      productId: data?['productId'],
      productTitle: data?['productTitle'],
      productImageUrl: data?['productImageUrl'],
      productPrice: (data?['productPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'type': type,
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'productPrice': productPrice,
    };
  }
}

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
    // Optional Product Data
    String type = 'text',
    String? productId,
    String? productTitle,
    String? productImageUrl,
    double? productPrice,
  }) async {
    // Allow empty text only if it's a product card
    if (text.trim().isEmpty && type == 'text') return;

    final newMessage = MarketplaceMessage(
      senderId: senderId,
      receiverId: receiverId,
      text: text,
      timestamp: Timestamp.now(),
      type: type,
      productId: productId,
      productTitle: productTitle,
      productImageUrl: productImageUrl,
      productPrice: productPrice,
    );

    await _chatsCollection
        .doc(chatRoomId)
        .collection('messages')
        .withConverter<MarketplaceMessage>(
          fromFirestore: MarketplaceMessage.fromFirestore,
          toFirestore: (message, _) => message.toFirestore(),
        )
        .add(newMessage);

    // Update the main chat document
    await _chatsCollection.doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': type == 'product' ? 'Sent a product: $productTitle' : text,
      'lastMessageTimestamp': newMessage.timestamp,
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<MarketplaceMessage>> getMessages(String chatRoomId) {
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatList(String userId) {
    return _chatsCollection
            .where('participants', arrayContains: userId)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots()
        as Stream<QuerySnapshot<Map<String, dynamic>>>;
  }
}
