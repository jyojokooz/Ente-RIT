// chat_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  Future<void> _deleteConversation(String chatRoomId) async {
    // ... This method is unchanged
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId);
    await chatDocRef.delete();
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
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: _currentUser.uid)
                .orderBy('lastMessageTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          // ... waiting and no data states are unchanged ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No active chats.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final chatDoc = conversations[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final chatRoomId = chatDoc.id;

              // --- MODIFICATION: Extract the unread count ---
              // Use null-aware operators to safely get the count.
              final unreadCounts =
                  chatData['unreadCounts'] as Map<String, dynamic>? ?? {};
              final unreadCount = unreadCounts[_currentUser.uid] as int? ?? 0;
              
              // ... rest of the variable assignments are unchanged ...
              final List<dynamic> participants = chatData['participants'];
              final otherUserId = participants.firstWhere(
                (id) => id != _currentUser.uid,
              );
              final otherUserName =
                  chatData['participantNames'][otherUserId] ?? 'User';
              final otherUserImage =
                  chatData['participantImages'][otherUserId] ?? '';
              final lastMessage = chatData['lastMessage'] ?? '';
              final timestamp =
                  (chatData['lastMessageTimestamp'] as Timestamp?)?.toDate();

              return Dismissible(
                key: Key(chatRoomId),
                // ... dismissible properties are unchanged ...
                background: Container(
                  color: Colors.red.shade800,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_forever, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteConversation(chatRoomId);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundImage: otherUserImage.isNotEmpty
                        ? NetworkImage(otherUserImage)
                        : null,
                    child: otherUserImage.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(otherUserName),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    // --- MODIFICATION: Make text bold if there are unread messages ---
                    style: TextStyle(
                      color: unreadCount > 0 ? Colors.white : Colors.white70,
                      fontWeight:
                          unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  // --- MODIFICATION: Update the trailing widget to show the count ---
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (timestamp != null)
                        Text(
                          DateFormat('h:mm a').format(timestamp),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      if (unreadCount > 0)
                        Chip(
                          label: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: Colors.yellow.shade700,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 0),
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      else
                        // Add a spacer to keep alignment consistent
                        const SizedBox(height: 24),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: otherUserId,
                          receiverName: otherUserName,
                          receiverImageUrl: otherUserImage,
                        ),
                      ),
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