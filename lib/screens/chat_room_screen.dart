import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String roomName;
  final String userId;
  final String userName;
  final String userProfilePicUrl;
  final bool isHost;

  const ChatRoomScreen({
    super.key,
    required this.roomName,
    required this.userId,
    required this.userName,
    required this.userProfilePicUrl,
    required this.isHost,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _roomExistenceSubscription;

  @override
  void initState() {
    super.initState();
    if (!widget.isHost) {
      _roomExistenceSubscription = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomName)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists) {
              _showRoomClosedDialog();
            }
          });
    }
  }

  void _showRoomClosedDialog() {
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      Navigator.of(context).pop();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            title: Text(
              'Room Closed',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: const Text(
              'The host has closed the room.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.cyan.shade400),
                ),
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
              ),
            ],
          ),
    );
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Delete Room?',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to permanently delete this room?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red.shade400),
              ),
              onPressed: () async {
                await _chatService.deleteRoom(widget.roomName, widget.userId);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleSendPressed() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      final message = ChatMessage(
        text: text,
        sender: widget.userName,
        timestamp: DateTime.now(),
        senderProfilePicUrl: widget.userProfilePicUrl,
      );
      _chatService.sendMessage(widget.roomName, message);
      _textController.clear();
      _scrollToBottom(isDelayed: true);
    }
  }

  void _scrollToBottom({bool isDelayed = false}) {
    final delay = Duration(milliseconds: isDelayed ? 300 : 100);
    Future.delayed(delay, () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _roomExistenceSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    if (widget.isHost) {
      _chatService.deleteRoom(widget.roomName, widget.userId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.roomName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.grey.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.isHost)
            IconButton(
              icon: Icon(
                Icons.delete_forever_outlined,
                color: Colors.red.shade400,
              ),
              tooltip: 'Delete Room',
              onPressed: _showDeleteConfirmationDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessageStream(widget.roomName),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'Be the first to say something!',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading messages.',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByMe = message.sender == widget.userName;
                    return _buildMessageBubble(message, isSentByMe);
                  },
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isSentByMe) {
    final alignment =
        isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isSentByMe ? Colors.cyan.shade600 : Colors.grey.shade800;
    final avatar = CircleAvatar(
      backgroundImage: NetworkImage(message.senderProfilePicUrl),
      radius: 20,
    );
    final messageBody = Column(
      crossAxisAlignment: alignment,
      children: [
        if (!isSentByMe)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
            child: Text(
              message.sender,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
          ),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment:
            isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[avatar, const SizedBox(width: 8)],
          messageBody,
          if (isSentByMe) ...[const SizedBox(width: 8), avatar],
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: Colors.grey.shade900,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message as ${widget.userName}...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  // THIS IS THE CORRECTED LINE
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: BorderSide(color: Colors.cyan.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                ),
                onSubmitted: (_) => _handleSendPressed(),
              ),
            ),
            const SizedBox(width: 8.0),
            IconButton(
              icon: Icon(Icons.send, color: Colors.cyan.shade400),
              onPressed: _handleSendPressed,
            ),
          ],
        ),
      ),
    );
  }
}
