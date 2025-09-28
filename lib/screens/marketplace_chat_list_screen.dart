import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/marketplace_chat_service.dart';
import 'marketplace_chat_screen.dart';

class MarketplaceChatListScreen extends StatefulWidget {
  const MarketplaceChatListScreen({super.key});

  @override
  State<MarketplaceChatListScreen> createState() =>
      _MarketplaceChatListScreenState();
}

class _MarketplaceChatListScreenState extends State<MarketplaceChatListScreen> {
  final MarketplaceChatService _chatService = MarketplaceChatService();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  // Helper to get the other user's info from a list of participants
  Future<Map<String, String>> _getOtherParticipantInfo(
    List<dynamic> participants,
  ) async {
    final otherUserId = participants.firstWhere(
      (id) => id != _currentUser.uid,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) {
      return {'id': '', 'name': 'Unknown User', 'imageUrl': ''};
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      return {
        'id': otherUserId,
        'name': data['displayName'] ?? 'User',
        'imageUrl': data['profilePhotoUrl'] ?? '',
      };
    }
    return {'id': otherUserId, 'name': 'Deleted User', 'imageUrl': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed background to white
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // This is a main tab, no back button needed
        title: Text(
          'Marketplace Chats',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getChatList(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.red),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chat = chatDocs[index];
              final data = chat.data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>;
              final lastMessage = data['lastMessage'] ?? '';
              final timestamp =
                  (data['lastMessageTimestamp'] as Timestamp?)?.toDate();

              return FutureBuilder<Map<String, String>>(
                future: _getOtherParticipantInfo(participants),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    // Use a placeholder while fetching user info
                    return const ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.black12,
                      ),
                      title: Text("Loading chat..."),
                    );
                  }
                  final otherUser = userSnapshot.data!;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          otherUser['imageUrl']!.isNotEmpty
                              ? NetworkImage(otherUser['imageUrl']!)
                              : null,
                      child:
                          otherUser['imageUrl']!.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                    ),
                    // --- THIS IS THE FIX ---
                    // Explicitly setting the text colors to be visible on a white background.
                    title: Text(
                      otherUser['name']!,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Readable dark color
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.black54, // Lighter grey for subtitle
                      ),
                    ),
                    trailing:
                        timestamp != null
                            ? Text(
                              DateFormat.jm().format(timestamp),
                              style: GoogleFonts.poppins(
                                color:
                                    Colors
                                        .grey
                                        .shade600, // Even lighter grey for timestamp
                                fontSize: 12,
                              ),
                            )
                            : null,
                    // --- END OF FIX ---
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => MarketplaceChatScreen(
                                receiverId: otherUser['id']!,
                                receiverName: otherUser['name']!,
                                receiverImageUrl: otherUser['imageUrl']!,
                              ),
                        ),
                      );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No marketplace chats yet.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact a seller to start a conversation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
