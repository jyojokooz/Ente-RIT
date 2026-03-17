// ===============================
// FILE NAME: chat_list_screen.dart
// FILE PATH: lib/screens/chat_list_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors matching the modern design
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(color: cardColor, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(Icons.edit_square, color: textColor, size: 20),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("New Message feature coming soon!"),
                  ),
                );
              },
            ),
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
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDark, textColor);
          }

          final conversations = snapshot.data!.docs;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search Bar Header
              SliverToBoxAdapter(
                child: _buildSearchBar(isDark, cardColor, textColor),
              ),

              // Messages List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final chatDoc = conversations[index];
                    return _buildChatTile(
                      chatDoc,
                      isDark,
                      cardColor,
                      textColor,
                    );
                  }, childCount: conversations.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.poppins(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
            hintText: 'Search messages...',
            hintStyle: GoogleFonts.poppins(
              color: isDark ? Colors.white54 : Colors.grey,
              fontSize: 14,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(
    DocumentSnapshot chatDoc,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
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

    final mutedTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Dismissible(
          key: Key(chatRoomId),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: Colors.redAccent,
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Avatar with Gradient Ring if unread
                  Container(
                    padding: EdgeInsets.all(isUnread ? 3 : 0),
                    decoration:
                        isUnread
                            ? const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFF3E8E),
                                  Color(0xFFFF9A44),
                                ], // Pink to Orange
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            )
                            : null,
                    child: Container(
                      padding: EdgeInsets.all(isUnread ? 2 : 0),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                        backgroundImage:
                            otherUserImage.isNotEmpty
                                ? CachedNetworkImageProvider(otherUserImage)
                                : null,
                        child:
                            otherUserImage.isEmpty
                                ? Icon(Icons.person, color: mutedTextColor)
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name & Message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                otherUserName,
                                style: GoogleFonts.poppins(
                                  color: textColor,
                                  fontWeight:
                                      isUnread
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (timestamp != null)
                              Text(
                                _formatTime(timestamp),
                                style: GoogleFonts.poppins(
                                  color:
                                      isUnread
                                          ? const Color(0xFFFF3E8E)
                                          : mutedTextColor,
                                  fontSize: 11,
                                  fontWeight:
                                      isUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: GoogleFonts.poppins(
                                  color: isUnread ? textColor : mutedTextColor,
                                  fontWeight:
                                      isUnread
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isUnread)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF3E8E),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount > 9
                                      ? '9+'
                                      : unreadCount.toString(),
                                  style: GoogleFonts.poppins(
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with friends to start chatting.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
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
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
