// ===============================
// FILE NAME: chat_list_screen.dart
// FILE PATH: lib/screens/chat_list_screen.dart
// ===============================

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

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _deleteConversation(String chatRoomId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .delete();
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
    const Color brandBlack = Colors.black;
    const Color brandPurple = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'MESSAGES',
          style: GoogleFonts.archivoBlack(color: brandBlack, fontSize: 22),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: brandBlack),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: brandBlack, height: 2),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: _currentUser.uid)
                .orderBy('lastMessageTimestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandBlack),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active chats.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final chatDoc = conversations[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final chatRoomId = chatDoc.id;

              final unreadCounts =
                  chatData['unreadCounts'] as Map<String, dynamic>? ?? {};
              final unreadCount = unreadCounts[_currentUser.uid] as int? ?? 0;

              final List<dynamic> participants = chatData['participants'];
              final otherUserId = participants.firstWhere(
                (id) => id != _currentUser.uid,
                orElse: () => '',
              );
              if (otherUserId.isEmpty) return const SizedBox.shrink();

              final otherUserName =
                  chatData['participantNames'][otherUserId] ?? 'User';
              final otherUserImage =
                  chatData['participantImages'][otherUserId] ?? '';
              final lastMessage = chatData['lastMessage'] ?? '';
              final timestamp =
                  (chatData['lastMessageTimestamp'] as Timestamp?)?.toDate();

              // Staggered Animation
              final Animation<double> animation = CurvedAnimation(
                parent: _controller,
                curve: Interval(
                  (index / conversations.length) * 0.5,
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              );

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: Dismissible(
                    key: Key(chatRoomId),
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) => _deleteConversation(chatRoomId),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatScreen(
                                  receiverId: otherUserId,
                                  receiverName: otherUserName,
                                  receiverImageUrl: otherUserImage,
                                ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: brandBlack, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: brandBlack,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: brandBlack, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage:
                                    otherUserImage.isNotEmpty
                                        ? NetworkImage(otherUserImage)
                                        : null,
                                child:
                                    otherUserImage.isEmpty
                                        ? const Icon(
                                          Icons.person,
                                          color: brandBlack,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    otherUserName,
                                    style: GoogleFonts.archivoBlack(
                                      fontSize: 16,
                                      color: brandBlack,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastMessage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceMono(
                                      color:
                                          unreadCount > 0
                                              ? brandBlack
                                              : Colors.grey.shade600,
                                      fontWeight:
                                          unreadCount > 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (timestamp != null)
                                  Text(
                                    DateFormat('h:mm a').format(timestamp),
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                if (unreadCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: brandPurple,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: brandBlack),
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: GoogleFonts.spaceMono(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
