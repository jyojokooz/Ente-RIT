import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  // Use a Future to hold the state, so we can refresh it.
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _getConversations();
  }

  Future<List<Map<String, dynamic>>> _getConversations() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> conversations = await db.rawQuery('''
      SELECT T1.* FROM messages T1
      INNER JOIN (
        SELECT chatRoomId, MAX(timestamp) AS max_timestamp
        FROM messages
        GROUP BY chatRoomId
      ) T2 ON T1.chatRoomId = T2.chatRoomId AND T1.timestamp = T2.max_timestamp
      ORDER BY T1.timestamp DESC
    ''');
    return conversations;
  }

  // --- NEW METHOD TO DELETE A CONVERSATION ---
  Future<void> _deleteConversation(String chatRoomId) async {
    // 1. Delete all messages for this chat from the local database
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'messages',
      where: 'chatRoomId = ?',
      whereArgs: [chatRoomId],
    );

    // 2. Refresh the UI to show the chat has been removed
    setState(() {
      _conversationsFuture = _getConversations();
    });

    // 3. Show a confirmation message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation deleted.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No active chats.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final chatData = conversations[index];
              final chatRoomId = chatData['chatRoomId'] as String;
              final List<String> userIds = chatRoomId.split('_');
              final otherUserId = userIds.firstWhere(
                (id) => id != _currentUser.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              // --- WRAP THE LISTTILE IN A DISMISSIBLE WIDGET ---
              return Dismissible(
                // Each item must have a unique key. The chatRoomId is perfect.
                key: Key(chatRoomId),
                // Provide a background that appears when swiping
                background: Container(
                  color: Colors.red.shade800,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                // We only want to swipe from right to left
                direction: DismissDirection.endToStart,
                // The function that is called after the swipe animation is complete
                onDismissed: (direction) {
                  _deleteConversation(chatRoomId);
                },
                child: FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return const ListTile(title: Text("Loading chat..."));
                    }

                    final otherUserData =
                        userSnapshot.data!.data() as Map<String, dynamic>;
                    final timestamp = DateTime.fromMillisecondsSinceEpoch(
                      chatData['timestamp'],
                    );

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage:
                            otherUserData['profilePhotoUrl'] != null &&
                                    otherUserData['profilePhotoUrl'].isNotEmpty
                                ? NetworkImage(otherUserData['profilePhotoUrl'])
                                : null,
                        child:
                            otherUserData['profilePhotoUrl'] == null ||
                                    otherUserData['profilePhotoUrl'].isEmpty
                                ? const Icon(Icons.person)
                                : null,
                      ),
                      title: Text(otherUserData['displayName'] ?? 'User'),
                      subtitle: Text(
                        chatData['text'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat('h:mm a').format(timestamp),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatScreen(
                                  receiverId: otherUserId,
                                  receiverName:
                                      otherUserData['displayName'] ?? 'User',
                                  receiverImageUrl:
                                      otherUserData['profilePhotoUrl'] ?? '',
                                ),
                          ),
                        ).then((_) {
                          // When we return from a chat, refresh the list to show the latest message
                          setState(() {
                            _conversationsFuture = _getConversations();
                          });
                        });
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
