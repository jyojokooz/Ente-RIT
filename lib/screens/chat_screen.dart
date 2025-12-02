// ===============================
// FILE NAME: chat_screen.dart
// FILE PATH: lib/screens/chat_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String receiverImageUrl;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  late final String _chatRoomId;
  late final CollectionReference _messagesCollection;

  bool _showEmojiPicker = false;

  // --- YOUR BRAND COLOR ---
  final Color _brandPurple = const Color(0xFF9983F3);

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUser.uid, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');

    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId);
    _messagesCollection = chatDocRef.collection('messages');

    chatDocRef
        .update({'unreadCounts.${_currentUser.uid}': 0})
        .catchError((e) {});

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _clearChatHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text("Clear Chat?"),
            content: const Text(
              "This will permanently delete the message history.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Clear", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final instance = FirebaseFirestore.instance;
      final batch = instance.batch();
      final snapshot = await _messagesCollection.get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      final parentRef = instance.collection('chats').doc(_chatRoomId);
      batch.update(parentRef, {
        'lastMessage': '',
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: Text(
                  "Clear Chat",
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _clearChatHistory();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final batch = FirebaseFirestore.instance.batch();
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId);
    final newMessageRef = _messagesCollection.doc();
    final timestamp = FieldValue.serverTimestamp();

    batch.set(chatDocRef, {
      'participants': [_currentUser.uid, widget.receiverId],
      'participantNames': {
        _currentUser.uid: _currentUser.displayName ?? 'Me',
        widget.receiverId: widget.receiverName,
      },
      'participantImages': {
        _currentUser.uid: _currentUser.photoURL ?? '',
        widget.receiverId: widget.receiverImageUrl,
      },
      'lastMessage': text,
      'lastMessageTimestamp': timestamp,
      'unreadCounts.${widget.receiverId}': FieldValue.increment(1),
    }, SetOptions(merge: true));

    batch.set(newMessageRef, {
      'senderId': _currentUser.uid,
      'text': text,
      'timestamp': timestamp,
      'type': 'text',
    });

    await batch.commit();
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });
  }

  Future<bool> _onWillPop() async {
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
      return false;
    }
    return true;
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    final time = DateFormat('h:mm a').format(date);

    if (messageDate == today) {
      return "Today $time";
    } else if (messageDate == yesterday) {
      return "Yesterday $time";
    } else if (now.difference(date).inDays < 7) {
      return "${DateFormat('EEE').format(date)} $time";
    } else {
      return "${DateFormat('MMM d, h:mm a').format(date)}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use your Brand Purple here instead of Blue
    final Color myBubbleColor = _brandPurple;
    const Color otherBubbleColor = Color(0xFFEFEFEF);
    const Color inputBgColor = Color(0xFFF3F3F3);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: Colors.grey.shade100,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    widget.receiverImageUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.receiverImageUrl)
                        : null,
                child:
                    widget.receiverImageUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.grey, size: 20)
                        : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "Active now",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.black),
              onPressed: _showChatOptions,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    _messagesCollection
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: _brandPurple),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msgData =
                          messages[index].data() as Map<String, dynamic>;
                      final isMe = msgData['senderId'] == _currentUser.uid;
                      final timestamp =
                          (msgData['timestamp'] as Timestamp?)?.toDate() ??
                          DateTime.now();

                      final prevMessage =
                          (index < messages.length - 1)
                              ? messages[index + 1].data() as Map
                              : null;
                      final nextMessage =
                          (index > 0)
                              ? messages[index - 1].data() as Map
                              : null;

                      final bool isFirstInGroup =
                          prevMessage == null ||
                          prevMessage['senderId'] != msgData['senderId'];
                      final bool isLastInGroup =
                          nextMessage == null ||
                          nextMessage['senderId'] != msgData['senderId'];

                      bool showTimeHeader = false;
                      if (prevMessage != null) {
                        final prevTimestamp =
                            (prevMessage['timestamp'] as Timestamp?)?.toDate();
                        if (prevTimestamp != null) {
                          final diff = timestamp.difference(prevTimestamp);
                          if (diff.inMinutes > 60 ||
                              timestamp.day != prevTimestamp.day) {
                            showTimeHeader = true;
                          }
                        }
                      } else {
                        showTimeHeader = true;
                      }

                      return Column(
                        children: [
                          if (showTimeHeader)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                _getFormattedDate(timestamp),
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          _buildMessageBubble(
                            msgData['text'] ?? '',
                            isMe,
                            isFirstInGroup,
                            isLastInGroup,
                            myBubbleColor,
                            otherBubbleColor,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputBar(inputBgColor),
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: emoji.EmojiPicker(
                  onEmojiSelected: (category, emojiVal) {
                    _messageController.text += emojiVal.emoji;
                  },
                  config: emoji.Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: const emoji.EmojiViewConfig(
                      columns: 7,
                      backgroundColor: Color(0xFFF2F2F2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    String message,
    bool isMe,
    bool isFirst,
    bool isLast,
    Color myColor,
    Color otherColor,
  ) {
    const double r = 20.0;
    const double smallR = 4.0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 1,
          bottom: 1,
          left: isMe ? 50 : 0,
          right: isMe ? 0 : 50,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? myColor : otherColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(!isMe && !isFirst ? smallR : r),
            topRight: Radius.circular(isMe && !isFirst ? smallR : r),
            bottomLeft: Radius.circular(!isMe && !isLast ? smallR : r),
            bottomRight: Radius.circular(isMe && !isLast ? smallR : r),
          ),
        ),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            color: isMe ? Colors.white : Colors.black,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // Camera Icon background set to Brand Purple
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _brandPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  focusNode: _focusNode,
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: _toggleEmojiPicker,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Send",
                  style: TextStyle(
                    color:
                        _brandPurple, // Send button text color is now Brand Purple
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
