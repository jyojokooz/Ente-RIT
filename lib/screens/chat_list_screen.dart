// ===============================
// FILE NAME: chat_list_screen.dart
// FILE PATH: lib/screens/chat_list_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Ensure this is in pubspec.yaml
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _deleteConversation(String chatRoomId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatRoomId)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation deleted.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    const Color brandPurple = Color(0xFF9983F3);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brandBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentUser.displayName ?? 'Username',
          style: GoogleFonts.poppins(
            color: brandBlack,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: brandBlack),
            onPressed: () {
              // TODO: Implement "New Message" search user screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("New Message feature coming soon!"),
                ),
              );
            },
          ),
        ],
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
              child: CircularProgressIndicator(color: brandPurple),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = snapshot.data!.docs;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search Bar Header
              SliverToBoxAdapter(child: _buildSearchBar()),

              // Messages List
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final chatDoc = conversations[index];
                  return _buildChatTile(chatDoc, brandPurple);
                }, childCount: conversations.length),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF), // Instagram-style grey
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            hintText: 'Search',
            hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(DocumentSnapshot chatDoc, Color accentColor) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final chatRoomId = chatDoc.id;

    // Get Unread Status
    final unreadCounts =
        chatData['unreadCounts'] as Map<String, dynamic>? ?? {};
    final int unreadCount = unreadCounts[_currentUser.uid] as int? ?? 0;
    final bool isUnread = unreadCount > 0;

    // Get Other User Info
    final List<dynamic> participants = chatData['participants'];
    final otherUserId = participants.firstWhere(
      (id) => id != _currentUser.uid,
      orElse: () => '',
    );
    if (otherUserId.isEmpty) return const SizedBox.shrink();

    final otherUserName = chatData['participantNames'][otherUserId] ?? 'User';
    final otherUserImage = chatData['participantImages'][otherUserId] ?? '';
    final lastMessage = chatData['lastMessage'] ?? 'Started a chat';
    final timestamp =
        (chatData['lastMessageTimestamp'] as Timestamp?)?.toDate();

    return Dismissible(
      key: Key(chatRoomId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.redAccent,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteConversation(chatRoomId),
      child: InkWell(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    otherUserImage.isNotEmpty
                        ? CachedNetworkImageProvider(otherUserImage)
                        : null,
                child:
                    otherUserImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
              ),
              const SizedBox(width: 14),

              // Name & Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      otherUserName,
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontWeight:
                            isUnread ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: GoogleFonts.poppins(
                              color: isUnread ? Colors.black : Colors.grey[600],
                              fontWeight:
                                  isUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timestamp != null) ...[
                          const SizedBox(width: 4),
                          Text(
                            " · ${_formatTime(timestamp)}",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Unread Indicator (Blue/Purple Dot)
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),

              // Optional: Camera Icon like Instagram (Purely visual here)
              if (!isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: const Icon(
              Icons.near_me_outlined,
              size: 60,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Message your friends',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send private photos and messages to a friend.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inDays > 6) {
      return '${diff.inDays ~/ 7}w';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else {
      return '${diff.inMinutes}m';
    }
  }
}
