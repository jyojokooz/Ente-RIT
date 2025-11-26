// ===============================
// FILE NAME: chat_screen.dart
// FILE PATH: lib/screens/chat_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    as emoji; // Prefix added
import 'package:flutter/foundation.dart' as foundation;

// ignore: unused_import
import '../widgets/chat_message_placeholder.dart';

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
  late final DocumentReference _chatDocRef;
  late final CollectionReference<Map<String, dynamic>> _messagesCollection;

  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUser.uid, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');

    _chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId);
    _messagesCollection = _chatDocRef
        .collection('messages')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        );

    _resetUnreadCount();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() => _showEmojiPicker = false);
      }
    });
  }

  void _resetUnreadCount() async {
    try {
      await _chatDocRef.update({'unreadCounts.${_currentUser.uid}': 0});
    } catch (e) {
      // Expected if chat doc doesn't exist yet.
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();
    final userData = userDoc.data() ?? {};
    final senderName = userData['displayName'] ?? 'A User';
    final senderImageUrl = userData['profilePhotoUrl'] ?? '';

    final batch = FirebaseFirestore.instance.batch();
    final newMessageRef = _messagesCollection.doc();

    batch.set(_chatDocRef, {
      'participants': [_currentUser.uid, widget.receiverId],
      'participantNames': {
        _currentUser.uid: senderName,
        widget.receiverId: widget.receiverName,
      },
      'participantImages': {
        _currentUser.uid: senderImageUrl,
        widget.receiverId: widget.receiverImageUrl,
      },
      'lastMessage': text,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'unreadCounts.${widget.receiverId}': FieldValue.increment(1),
    }, SetOptions(merge: true));

    batch.set(newMessageRef, {
      'senderId': _currentUser.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
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

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    const Color brandPurple = Color(0xFF9983F3);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: brandBlack),
          title: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: brandBlack, width: 2),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      widget.receiverImageUrl.isNotEmpty
                          ? NetworkImage(widget.receiverImageUrl)
                          : null,
                  child:
                      widget.receiverImageUrl.isEmpty
                          ? const Icon(Icons.person, color: brandBlack)
                          : null,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.receiverName,
                style: GoogleFonts.archivoBlack(
                  color: brandBlack,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(color: brandBlack, height: 2),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    _messagesCollection
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: brandBlack),
                    );
                  }

                  final messages = snapshot.data?.docs ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hello! 👋',
                        style: GoogleFonts.spaceMono(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();
                      final isMe = data['senderId'] == _currentUser.uid;
                      final timestamp = data['timestamp'] as Timestamp?;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment:
                              isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? brandPurple : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft:
                                      isMe
                                          ? const Radius.circular(16)
                                          : Radius.zero,
                                  bottomRight:
                                      isMe
                                          ? Radius.zero
                                          : const Radius.circular(16),
                                ),
                                border: Border.all(color: brandBlack, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: brandBlack,
                                    offset: Offset(isMe ? -4 : 4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['text'] ?? '',
                                    style: GoogleFonts.poppins(
                                      color: isMe ? Colors.white : brandBlack,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timestamp != null
                                        ? DateFormat(
                                          'h:mm a',
                                        ).format(timestamp.toDate())
                                        : '...',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 10,
                                      color:
                                          isMe
                                              ? Colors.white70
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: brandBlack, width: 2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker
                          ? Icons.keyboard
                          : Icons.emoji_emotions_outlined,
                      color: Colors.grey.shade700,
                    ),
                    onPressed: _toggleEmojiPicker,
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: brandBlack, width: 2),
                      ),
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(color: brandBlack),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.spaceMono(
                            color: Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: brandPurple,
                        shape: BoxShape.circle,
                        border: Border.all(color: brandBlack, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: brandBlack,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                // Use 'emoji.EmojiPicker' due to the prefix we added
                child: emoji.EmojiPicker(
                  onEmojiSelected: (category, emojiVal) {
                    _messageController.text += emojiVal.emoji;
                  },
                  // Use 'emoji.Config' due to the prefix
                  config: emoji.Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: emoji.EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax:
                          28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.20
                              : 1.0),
                      backgroundColor: const Color(0xFFF2F2F2),
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
