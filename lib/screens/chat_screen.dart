import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../helpers/database_helper.dart';
import '../widgets/chat_message_placeholder.dart';

// --- Models ---
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String senderImageUrl;
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.senderImageUrl,
  });
}

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
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  final String pusherAppKey = dotenv.env['PUSHER_APP_KEY'] ?? '';
  final String pusherAppCluster = dotenv.env['PUSHER_APP_CLUSTER'] ?? '';

  // --- FIX: Simplified data model. The list now only holds ChatMessage objects. ---
  final List<ChatMessage> _chatMessages = [];
  bool _isLoadingHistory = true;
  String _currentUserImageUrl = '';
  final uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUser.uid, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');
    _initializeChat();
  }

  @override
  void dispose() {
    pusher.unsubscribe(channelName: 'private-$_chatRoomId');
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();
    if (userDoc.exists) {
      _currentUserImageUrl = userDoc.data()?['profilePhotoUrl'] ?? '';
    }

    final historyData = await DatabaseHelper.instance.getMessages(
      _chatRoomId,
      _currentUser.uid,
    );
    final historyMessages =
        historyData.map((item) {
          final isMe = item['senderId'] == _currentUser.uid;
          return ChatMessage(
            id: item['messageId'],
            senderId: item['senderId'],
            text: item['text'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              item['timestamp'],
              isUtc: true,
            ),
            senderImageUrl:
                isMe ? _currentUserImageUrl : widget.receiverImageUrl,
          );
        }).toList();

    // --- FIX: Add all historical messages directly to the list. ---
    _chatMessages.addAll(historyMessages);

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
      });
    }

    try {
      await pusher.init(
        apiKey: pusherAppKey,
        cluster: pusherAppCluster,
        onEvent: _onPusherEvent,
      );
      await pusher.subscribe(channelName: 'private-$_chatRoomId');
      await pusher.connect();
    } catch (e) {
      // Handle Pusher connection error
      debugPrint("Pusher Error: $e");
    }
  }

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName == 'client-new-message') {
      final data = jsonDecode(event.data);
      if (data['senderId'] != _currentUser.uid) {
        final newMessage = ChatMessage(
          id: data['messageId'],
          senderId: data['senderId'],
          text: data['text'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'],
            isUtc: true,
          ),
          senderImageUrl: widget.receiverImageUrl,
        );
        DatabaseHelper.instance.insertMessage({
          'messageId': newMessage.id,
          'chatRoomId': _chatRoomId,
          'senderId': newMessage.senderId,
          'text': newMessage.text,
          'timestamp': newMessage.timestamp.millisecondsSinceEpoch,
        });
        if (mounted) {
          setState(() {
            // --- FIX: Add new messages to the start of the list for the reversed view. ---
            _chatMessages.insert(0, newMessage);
          });
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageId = uuid.v4();
    final message = ChatMessage(
      id: messageId,
      senderId: _currentUser.uid,
      text: text,
      timestamp: DateTime.now().toUtc(),
      senderImageUrl: _currentUserImageUrl,
    );
    _messageController.clear();

    setState(() {
      _chatMessages.insert(0, message);
    });

    await DatabaseHelper.instance.insertMessage({
      'messageId': message.id,
      'chatRoomId': _chatRoomId,
      'senderId': message.senderId,
      'text': message.text,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    });
    await pusher.trigger(
      PusherEvent(
        channelName: 'private-$_chatRoomId',
        eventName: 'client-new-message',
        data: jsonEncode({
          'messageId': message.id,
          'senderId': message.senderId,
          'text': message.text,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
        }),
      ),
    );
  }

  Future<void> _deleteMessageForMe(String messageId) async {
    await DatabaseHelper.instance.markMessageAsDeletedFor(
      messageId,
      _currentUser.uid,
    );
    if (mounted) {
      setState(() {
        _chatMessages.removeWhere((msg) => msg.id == messageId);
      });
    }
  }

  void _showDeleteDialog(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              child: Wrap(
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete for me',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        _deleteMessageForMe(messageId);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      title: const Center(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatDateSeparator(DateTime date) {
    final location = tz.getLocation('Asia/Kolkata');
    final istTime = tz.TZDateTime.from(date, location);
    final now = tz.TZDateTime.now(location);
    final today = tz.TZDateTime(location, now.year, now.month, now.day);
    final yesterday = tz.TZDateTime(location, now.year, now.month, now.day - 1);
    final messageDate = tz.TZDateTime(
      location,
      istTime.year,
      istTime.month,
      istTime.day,
    );
    if (messageDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(istTime);
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    final location = tz.getLocation('Asia/Kolkata');
    final dt1 = tz.TZDateTime.from(d1, location);
    final dt2 = tz.TZDateTime.from(d2, location);
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
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
            child:
                _isLoadingHistory
                    ? ListView.builder(
                      reverse: true,
                      itemCount: 10,
                      padding: const EdgeInsets.all(12.0),
                      itemBuilder:
                          (context, index) =>
                              ChatMessagePlaceholder(isMe: index.isEven),
                    )
                    : _chatMessages.isEmpty
                    ? Center(
                      child: Text(
                        'Say hello!',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final message = _chatMessages[index];
                        final isMe = message.senderId == _currentUser.uid;

                        // --- FIX: Logic for showing avatars and timestamps correctly in a reversed list ---
                        // Show avatar only on the last message of a consecutive block.
                        // In a reversed list, the "last" message is the one with the lowest index (e.g., index 0).
                        final isLastInBlock =
                            (index == 0) ||
                            (_chatMessages[index - 1].senderId !=
                                message.senderId);

                        // --- FIX: Logic for showing date separators correctly in a reversed list ---
                        // Show date separator if it's the oldest message or if the day changed.
                        // In a reversed list, the "next" message (older) is at index + 1.
                        final bool showDateSeparator =
                            (index == _chatMessages.length - 1) ||
                            !_isSameDay(
                              message.timestamp,
                              _chatMessages[index + 1].timestamp,
                            );

                        return Column(
                          children: [
                            if (showDateSeparator)
                              _buildDateSeparator(message.timestamp),
                            GestureDetector(
                              onLongPress: () {
                                if (isMe) _showDeleteDialog(message.id);
                              },
                              child: _buildMessageBubble(
                                message: message,
                                isMe: isMe,
                                isLastInBlock: isLastInBlock,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _formatDateSeparator(date),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage message,
    required bool isMe,
    required bool isLastInBlock,
  }) {
    final location = tz.getLocation('Asia/Kolkata');
    final istTime = tz.TZDateTime.from(message.timestamp, location);
    final formattedTime = DateFormat('HH:mm').format(istTime);

    // --- UI REFRESH: Tailed corners for a more modern chat look ---
    final bubbleRadius = Radius.circular(20);
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
          // Show avatar for the other user
          if (!isMe && isLastInBlock)
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  message.senderImageUrl.isNotEmpty
                      ? NetworkImage(message.senderImageUrl)
                      : null,
              child:
                  message.senderImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 16)
                      : null,
            )
          else if (!isMe)
            const SizedBox(width: 32), // Spacer to align messages
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
                    // --- UI REFRESH: New colors ---
                    color: isMe ? Colors.blue : Colors.grey.shade800,
                    borderRadius: bubbleBorderRadius,
                  ),
                  child: Text(
                    message.text,
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
              icon: const Icon(Icons.send, color: Colors.blue), // UI Refresh
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
