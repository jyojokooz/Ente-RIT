// lib/screens/item_chats_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_project/features/chat/presentation/private_chat_screen.dart'; // Your private chat screen

class ItemChatsListScreen extends StatelessWidget {
  final String itemId;
  final String itemTitle;

  const ItemChatsListScreen({
    super.key,
    required this.itemId,
    required this.itemTitle,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(/* ... error handling ... */);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Inquiries for "$itemTitle"',
          style: GoogleFonts.poppins(fontSize: 18),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- THE FIX IS HERE ---
        // The query now includes both the itemId and a check that the current user
        // is a participant. This perfectly matches our security rules.
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('itemId', isEqualTo: itemId)
                .where(
                  'users',
                  arrayContains: currentUser.uid,
                ) // <<< --- ADD THIS LINE
                .orderBy('lastMessageTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (snapshot.hasError) {
            // This will now show a new error asking for an index.
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No inquiries yet for this item.',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
            );
          }

          final chatDocs = snapshot.data!.docs;
          // ... The rest of the code is exactly the same ...
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8.0),
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              final List<dynamic> userIds = chatData['users'] ?? [];
              final String otherUserId = userIds.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );
              final Map<String, dynamic> userNames =
                  chatData['userNames'] ?? {};
              final String otherUserName =
                  userNames[otherUserId] ?? 'Unknown User';

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.yellow.withAlpha(204),
                    child: Text(
                      otherUserName.isNotEmpty
                          ? otherUserName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    otherUserName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    chatData['lastMessage'] ?? 'No messages yet.',
                    style: GoogleFonts.poppins(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PrivateChatScreen(
                              chatId: chatDoc.id,
                              otherUserName: otherUserName,
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
