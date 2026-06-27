import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

// A data model class for chat messages, now with helper methods for Firestore.
class ChatMessage {
  final String text;
  final String sender;
  final String senderId; // <-- NEW FIELD
  final DateTime timestamp;
  final String senderProfilePicUrl;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.senderId, // <-- NEW FIELD
    required this.timestamp,
    required this.senderProfilePicUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Use senderId for the avatar seed as it's guaranteed to be unique
    final defaultAvatar =
        'https://api.dicebear.com/7.x/pixel-art/png?seed=${map['senderId'] ?? 'default'}';
    return ChatMessage(
      text: map['text'] ?? '',
      sender: map['sender'] ?? 'Unknown',
      senderId: map['senderId'] ?? '', // <-- NEW FIELD
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      senderProfilePicUrl: map['senderProfilePicUrl'] ?? defaultAvatar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender,
      'senderId': senderId, // <-- NEW FIELD
      'timestamp': Timestamp.fromDate(timestamp),
      'senderProfilePicUrl': senderProfilePicUrl,
    };
  }
}

// A data model for room information
class Room {
  final String name; // Document ID
  final String hostId;

  Room({required this.name, required this.hostId});

  factory Room.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(name: doc.id, hostId: data['hostId'] ?? '');
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Stream<List<Room>> get onRoomListChanged {
    return _firestore.collection('rooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Room.fromSnapshot(doc)).toList();
    });
  }

  Future<bool> createRoom(String name, String password, String hostId) async {
    final trimmedName = name.trim();
    final trimmedPassword = password.trim();
    if (trimmedName.isEmpty || trimmedPassword.isEmpty) {
      return false;
    }
    try {
      final roomDocRef = _firestore.collection('rooms').doc(trimmedName);
      final doc = await roomDocRef.get();
      if (doc.exists) {
        return false;
      }
      await roomDocRef.set({
        'passwordHash': _hashPassword(trimmedPassword),
        'hostId': hostId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteRoom(String roomName, String userId) async {
    try {
      final roomDocRef = _firestore.collection('rooms').doc(roomName);
      final doc = await roomDocRef.get();
      if (doc.exists && doc.data()?['hostId'] == userId) {
        final messagesSnapshot = await roomDocRef.collection('messages').get();
        for (var msg in messagesSnapshot.docs) {
          await msg.reference.delete();
        }
        await roomDocRef.delete();
      }
    } catch (e) {
      // Silently fail on error
    }
  }

  Future<bool> verifyPassword(String roomName, String password) async {
    try {
      final trimmedPassword = password.trim();
      final doc = await _firestore.collection('rooms').doc(roomName).get();
      if (!doc.exists) {
        return false;
      }
      final data = doc.data();
      final storedHash = data?['passwordHash'] as String?;
      if (storedHash != null && storedHash.isNotEmpty) {
        return storedHash == _hashPassword(trimmedPassword);
      }

      // Legacy room support: migrate plaintext password to hash on first valid check.
      final legacyPassword = data?['password'] as String?;
      if (legacyPassword != null && legacyPassword == trimmedPassword) {
        await doc.reference.update({
          'passwordHash': _hashPassword(trimmedPassword),
          'password': FieldValue.delete(),
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void sendMessage(String roomName, ChatMessage message) {
    _firestore
        .collection('rooms')
        .doc(roomName)
        .collection('messages')
        .add(message.toMap());
  }

  Stream<List<ChatMessage>> getMessageStream(String roomName) {
    return _firestore
        .collection('rooms')
        .doc(roomName)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data()))
              .toList();
        });
  }
}
