import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../services/marketplace_chat_service.dart'; // Make sure this path is correct

class MarketplaceChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImageUrl;

  const MarketplaceChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImageUrl,
  });

  @override
  State<MarketplaceChatScreen> createState() => _MarketplaceChatScreenState();
}

class _MarketplaceChatScreenState extends State<MarketplaceChatScreen> {
  // ... (initState, dispose, and other methods are unchanged) ...
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = MarketplaceChatService();
  final _currentUser = FirebaseAuth.instance.currentUser!;
  late final String _chatRoomId;

  @override
  void initState() {
    super.initState();
    _chatRoomId = _chatService.getChatRoomId(
      _currentUser.uid,
      widget.receiverId,
    );
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      _chatService.sendMessage(
        chatRoomId: _chatRoomId,
        text: _messageController.text,
        senderId: _currentUser.uid,
        receiverId: widget.receiverId,
      );

      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(widget.receiverImageUrl),
            ),
            const SizedBox(width: 12),
            Text(
              widget.receiverName,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            // --- CHANGE: The StreamBuilder now expects MarketplaceMessage objects ---
            child: StreamBuilder<QuerySnapshot<MarketplaceMessage>>(
              stream: _chatService.getMessages(_chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello!',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    // --- SIMPLIFIED: .data() now directly gives a MarketplaceMessage object! ---
                    final currentMessage = messages[index].data();

                    final prevMessage =
                        (index < messages.length - 1)
                            ? messages[index + 1].data()
                            : null;

                    final bool isMe =
                        currentMessage.senderId == _currentUser.uid;
                    final bool isSameDay =
                        prevMessage != null &&
                        currentMessage.timestamp.toDate().day ==
                            prevMessage.timestamp.toDate().day;

                    final bool showDateDivider = !isSameDay;
                    final bool isFirstInGroup =
                        prevMessage == null ||
                        prevMessage.senderId != currentMessage.senderId ||
                        !isSameDay;

                    return Column(
                      children: [
                        if (showDateDivider)
                          _DateDivider(date: currentMessage.timestamp.toDate()),
                        _MessageBubble(
                          message: currentMessage.text,
                          isMe: isMe,
                          isFirstInGroup: isFirstInGroup,
                          timestamp: currentMessage.timestamp.toDate(),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  // The _buildMessageInputField, _MessageBubble, and _DateDivider widgets remain unchanged.
  // ... (paste the rest of your UI code here) ...
  Widget _buildMessageInputField() {
    final bool canSend = _messageController.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.poppins(color: Colors.black54),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child:
                  canSend
                      ? IconButton(
                        key: const ValueKey('send_button'),
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Colors.blueAccent,
                        ),
                        onPressed: _sendMessage,
                      )
                      : IconButton(
                        key: const ValueKey('attach_button'),
                        icon: const Icon(Icons.attach_file, color: Colors.grey),
                        onPressed: () {
                          // TODO: Implement attachment logic here
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for the message bubble
class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final bool isFirstInGroup;
  final DateTime timestamp;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isFirstInGroup,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final radius = const Radius.circular(18);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: isFirstInGroup ? 8.0 : 2.0,
          bottom: 2.0,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: radius,
            topRight: radius,
            bottomLeft:
                isMe
                    ? (isFirstInGroup ? radius : const Radius.circular(4))
                    : radius,
            bottomRight:
                isMe
                    ? radius
                    : (isFirstInGroup ? radius : const Radius.circular(4)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.poppins(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(timestamp),
              style: GoogleFonts.poppins(
                fontSize: 10,
                color:
                    isMe
                        ? Colors.white.withOpacity(0.7)
                        : Colors.black.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget for the date divider
class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCompare = DateTime(date.year, date.month, date.day);

    if (dateToCompare == today) {
      return 'Today';
    } else if (dateToCompare == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getFormattedDate(date),
            style: GoogleFonts.poppins(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
