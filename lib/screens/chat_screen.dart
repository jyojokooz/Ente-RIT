import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
  late final String _chatRoomId;
  late final DocumentReference _chatDocRef;
  // --- CHANGE 1: Specify the type of data in the CollectionReference ---
  late final CollectionReference<Map<String, dynamic>> _messagesCollection;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUser.uid, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');

    _chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId);
    // --- CHANGE 2: The type is inferred here from the variable's definition ---
    _messagesCollection = _chatDocRef
        .collection('messages')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data()!,
          toFirestore: (data, _) => data,
        );

    _resetUnreadCount();
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
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

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

    _messageController.clear();

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

  bool _isSameDay(Timestamp? t1, Timestamp? t2) {
    if (t1 == null || t2 == null) return false;
    final d1 = t1.toDate();
    final d2 = t2.toDate();
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDateSeparator(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.receiverImageUrl.isNotEmpty
                      ? NetworkImage(widget.receiverImageUrl)
                      : null,
              child:
                  widget.receiverImageUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
            ),
            const SizedBox(width: 12),
            Text(widget.receiverName, style: GoogleFonts.poppins()),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            // --- CHANGE 3: Specify the type for the StreamBuilder ---
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _messagesCollection
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    reverse: true,
                    itemCount: 10,
                    padding: const EdgeInsets.all(12.0),
                    itemBuilder:
                        (context, index) =>
                            ChatMessagePlaceholder(isMe: index.isEven),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hello!',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    // --- CHANGE 4: The cast `as Map<String, dynamic>` is now removed ---
                    final data = doc.data();
                    final isMe = data['senderId'] == _currentUser.uid;

                    final isLastInBlock =
                        (index == 0) ||
                        // --- CHANGE 5: Cast removed here ---
                        (messages[index - 1].data())['senderId'] !=
                            data['senderId'];

                    // The cast to Timestamp? is still needed because the map value is `dynamic`
                    final currentTimestamp = data['timestamp'] as Timestamp?;
                    final nextTimestamp =
                        (index < messages.length - 1)
                            // --- CHANGE 6: Cast removed here ---
                            ? (messages[index + 1].data())['timestamp']
                                as Timestamp?
                            : null;

                    final bool showDateSeparator =
                        (index == messages.length - 1) ||
                        !_isSameDay(currentTimestamp, nextTimestamp);

                    return Column(
                      children: [
                        if (showDateSeparator && currentTimestamp != null)
                          _buildDateSeparator(currentTimestamp),
                        _buildMessageBubble(
                          text: data['text'],
                          timestamp: data['timestamp'],
                          isMe: isMe,
                          isLastInBlock: isLastInBlock,
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

  Widget _buildDateSeparator(Timestamp timestamp) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatDateSeparator(timestamp),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required Timestamp? timestamp,
    required bool isMe,
    required bool isLastInBlock,
  }) {
    final formattedTime =
        timestamp != null
            ? DateFormat('HH:mm').format(timestamp.toDate())
            : '--:--';

    final bubbleRadius = const Radius.circular(20);
    final bubbleBorderRadius =
        isMe
            ? BorderRadius.only(
              topLeft: bubbleRadius,
              bottomLeft: bubbleRadius,
              bottomRight: isLastInBlock ? Radius.zero : bubbleRadius,
              topRight: bubbleRadius,
            )
            : BorderRadius.only(
              topRight: bubbleRadius,
              bottomRight: bubbleRadius,
              bottomLeft: isLastInBlock ? Radius.zero : bubbleRadius,
              topLeft: bubbleRadius,
            );

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLastInBlock ? 10.0 : 2.0,
        left: isMe ? 48.0 : 0,
        right: isMe ? 0 : 48.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && isLastInBlock)
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  widget.receiverImageUrl.isNotEmpty
                      ? NetworkImage(widget.receiverImageUrl)
                      : null,
              child:
                  widget.receiverImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 16)
                      : null,
            )
          else if (!isMe)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.blue : Colors.grey.shade800,
                    borderRadius: bubbleBorderRadius,
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
                if (isLastInBlock) ...[
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(color: Colors.grey.shade900),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blue),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
