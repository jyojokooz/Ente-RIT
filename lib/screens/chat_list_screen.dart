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

  // This function will fetch the last message for each chat room
  // from the local SQLite database.
  Future<List<Map<String, dynamic>>> _getConversations() async {
    final db = await DatabaseHelper.instance.database;
    // This is a complex SQL query to get the latest message from each chat room.
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
        future: _getConversations(),
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

              // Use another FutureBuilder to get the other user's profile details
              return FutureBuilder<DocumentSnapshot>(
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
                        // When we return from a chat, refresh the list
                        setState(() {});
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
