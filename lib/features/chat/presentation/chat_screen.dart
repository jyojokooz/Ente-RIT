// ===============================
// FILE NAME: chat_screen.dart
// FILE PATH: lib/screens/chat_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

// Import our new separated widgets
import 'package:my_project/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:my_project/features/chat/presentation/widgets/chat_bubble.dart';

// Import Profile Screen to navigate on tap
import 'package:my_project/features/profile/presentation/profile_screen.dart';

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

    // Mark messages as read
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

    // Ensure the receiver is added back to participants if they previously deleted the chat
    batch.set(chatDocRef, {
      'participants': FieldValue.arrayUnion([
        _currentUser.uid,
        widget.receiverId,
      ]),
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

  Future<void> _deleteSingleMessage(String messageId) async {
    try {
      await _messagesCollection.doc(messageId).delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
    }
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

  // Modern replacement for WillPopScope
  void _onPopInvoked(bool didPop) {
    if (didPop) return;
    if (_showEmojiPicker) {
      setState(() => _showEmojiPicker = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) return "Today";
    if (messageDate == yesterday) return "Yesterday";
    if (now.difference(date).inDays < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return PopScope(
      canPop: !_showEmojiPicker,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: bgColor,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0,
          // Wrap the title in GestureDetector to navigate to profile
          title: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProfileScreen(userId: widget.receiverId),
                ),
              );
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  backgroundImage:
                      widget.receiverImageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(widget.receiverImageUrl)
                          : null,
                  child:
                      widget.receiverImageUrl.isEmpty
                          ? Icon(Icons.person, color: subtitleColor, size: 20)
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiverName,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // StreamBuilder to check actual online status
                      StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.receiverId)
                                .snapshots(),
                        builder: (context, userSnapshot) {
                          bool isOnline = false;
                          String lastSeen = "Offline";

                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            final data =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            isOnline =
                                data['isOnline'] ??
                                false; // Make sure this field updates in your app

                            // Optional: Calculate last seen if not online
                            final Timestamp? lastLogin = data['lastLogin'];
                            if (lastLogin != null && !isOnline) {
                              final diff = DateTime.now().difference(
                                lastLogin.toDate(),
                              );
                              if (diff.inMinutes < 5) {
                                isOnline =
                                    true; // Consider online if active in last 5 mins
                              } else if (diff.inHours < 24) {
                                lastSeen =
                                    "Active ${diff.inHours > 0 ? '${diff.inHours}h' : '${diff.inMinutes}m'} ago";
                              } else {
                                lastSeen = "Active ${diff.inDays}d ago";
                              }
                            }
                          }

                          return Text(
                            isOnline ? "Active now" : lastSeen,
                            style: GoogleFonts.poppins(
                              color:
                                  isOnline
                                      ? const Color(0xFF43E97B)
                                      : subtitleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9983F3),
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.waving_hand_rounded,
                            size: 60,
                            color: subtitleColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Say hi to ${widget.receiverName.split(' ').first}!",
                            style: GoogleFonts.poppins(color: subtitleColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msgDoc = messages[index];
                      final msgData = msgDoc.data() as Map<String, dynamic>;
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
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _getFormattedDate(timestamp),
                                style: GoogleFonts.poppins(
                                  color: subtitleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                          // Call the separated ChatBubble widget
                          ChatBubble(
                            messageData: msgData,
                            messageId: msgDoc.id,
                            isMe: isMe,
                            isFirst: isFirstInGroup,
                            isLast: isLastInGroup,
                            timestamp: timestamp,
                            isDark: isDark,
                            cardColor: cardColor,
                            textColor: textColor,
                            onDelete: () => _deleteSingleMessage(msgDoc.id),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Call the separated InputBar widget
            ChatInputBar(
              controller: _messageController,
              focusNode: _focusNode,
              onSend: _sendMessage,
              onToggleEmoji: _toggleEmojiPicker,
              showEmojiPicker: _showEmojiPicker,
              isDark: isDark,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),

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
                    emojiViewConfig: emoji.EmojiViewConfig(
                      columns: 7,
                      backgroundColor:
                          isDark
                              ? const Color(0xFF161618)
                              : const Color(0xFFF2F2F2),
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
