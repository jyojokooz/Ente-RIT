import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:timezone/timezone.dart' as tz; // <-- 1. IMPORT TIMEZONE
import '../helpers/database_helper.dart';

// --- Models and Classes ---
abstract class ChatListItem {}

class MessageItem extends ChatListItem {
  final ChatMessage message;
  MessageItem(this.message);
}

class DateSeparatorItem extends ChatListItem {
  final DateTime date;
  DateSeparatorItem(this.date);
}

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String senderImageUrl;
  ChatMessage({
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
  final String pusherAppKey = "YOUR_PUSHER_KEY"; // Replace with your key
  final String pusherAppCluster =
      "YOUR_PUSHER_CLUSTER"; // Replace with your cluster

  List<ChatListItem> _chatItems = [];
  bool _isLoadingHistory = true;
  String _currentUserImageUrl = '';

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

    final historyData = await DatabaseHelper.instance.getMessages(_chatRoomId);
    final historyMessages =
        historyData.map((item) {
          final isMe = item['senderId'] == _currentUser.uid;
          return ChatMessage(
            senderId: item['senderId'],
            text: item['text'],
            // Timestamps from DB are UTC, so we create a UTC DateTime object
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              item['timestamp'],
              isUtc: true,
            ),
            senderImageUrl:
                isMe ? _currentUserImageUrl : widget.receiverImageUrl,
          );
        }).toList();

    if (mounted) {
      setState(() {
        _chatItems = _groupMessages(historyMessages);
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
      /* handle error */
    }
  }

  List<ChatListItem> _groupMessages(List<ChatMessage> messages) {
    if (messages.isEmpty) return [];
    List<ChatListItem> groupedItems = [];
    for (var i = 0; i < messages.length; i++) {
      final currentMessage = messages[i];
      groupedItems.add(MessageItem(currentMessage));
      final bool isLastMessage = i == messages.length - 1;
      if (isLastMessage) {
        groupedItems.add(DateSeparatorItem(currentMessage.timestamp));
      } else {
        final nextMessage = messages[i + 1];
        // Compare dates in the local timezone
        final location = tz.getLocation('Asia/Kolkata');
        final currentLocalTime = tz.TZDateTime.from(
          currentMessage.timestamp,
          location,
        );
        final nextLocalTime = tz.TZDateTime.from(
          nextMessage.timestamp,
          location,
        );
        if (currentLocalTime.day != nextLocalTime.day) {
          groupedItems.add(DateSeparatorItem(currentMessage.timestamp));
        }
      }
    }
    return groupedItems;
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

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName == 'client-new-message') {
      final data = jsonDecode(event.data);
      if (data['senderId'] != _currentUser.uid) {
        final newMessage = ChatMessage(
          senderId: data['senderId'],
          text: data['text'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            data['timestamp'],
            isUtc: true,
          ),
          senderImageUrl: widget.receiverImageUrl,
        );

        DatabaseHelper.instance.insertMessage({
          'chatRoomId': _chatRoomId,
          'senderId': newMessage.senderId,
          'text': newMessage.text,
          'timestamp': newMessage.timestamp.millisecondsSinceEpoch,
        });

        if (mounted) {
          setState(() {
            final firstItem = _chatItems.isNotEmpty ? _chatItems.first : null;
            bool isNewDay = true;
            if (firstItem is MessageItem) {
              final location = tz.getLocation('Asia/Kolkata');
              final lastLocalDate = tz.TZDateTime.from(
                firstItem.message.timestamp,
                location,
              );
              final newLocalDate = tz.TZDateTime.from(
                newMessage.timestamp,
                location,
              );
              isNewDay =
                  newLocalDate.day != lastLocalDate.day ||
                  newLocalDate.month != lastLocalDate.month ||
                  newLocalDate.year != lastLocalDate.year;
            }
            if (isNewDay) {
              _chatItems.insert(0, DateSeparatorItem(newMessage.timestamp));
            }
            _chatItems.insert(0, MessageItem(newMessage));
          });
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final utcNow = DateTime.now().toUtc();
    final message = ChatMessage(
      senderId: _currentUser.uid,
      text: text,
      timestamp: utcNow,
      senderImageUrl: _currentUserImageUrl,
    );

    _messageController.clear();
    setState(() {
      final firstItem = _chatItems.isNotEmpty ? _chatItems.first : null;
      bool isNewDay = true;
      if (firstItem is MessageItem) {
        final location = tz.getLocation('Asia/Kolkata');
        final lastLocalDate = tz.TZDateTime.from(
          firstItem.message.timestamp,
          location,
        );
        final newLocalDate = tz.TZDateTime.from(message.timestamp, location);
        isNewDay =
            newLocalDate.day != lastLocalDate.day ||
            newLocalDate.month != lastLocalDate.month ||
            newLocalDate.year != lastLocalDate.year;
      }
      if (isNewDay) {
        _chatItems.insert(0, DateSeparatorItem(message.timestamp));
      }
      _chatItems.insert(0, MessageItem(message));
    });

    await DatabaseHelper.instance.insertMessage({
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
          'senderId': message.senderId,
          'text': message.text,
          'timestamp': message.timestamp.millisecondsSinceEpoch,
        }),
      ),
    );
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
                    ? const Center(
                      child: CircularProgressIndicator(color: Colors.yellow),
                    )
                    : _chatItems.isEmpty
                    ? Center(
                      child: Text(
                        'Say hello!',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12.0),
                      itemCount: _chatItems.length,
                      itemBuilder: (context, index) {
                        final currentItem = _chatItems[index];
                        if (currentItem is DateSeparatorItem) {
                          return _buildDateSeparator(currentItem.date);
                        }
                        if (currentItem is MessageItem) {
                          final message = currentItem.message;
                          final isMe = message.senderId == _currentUser.uid;
                          bool showAvatarAndTimestamp = false;
                          if (index == 0) {
                            showAvatarAndTimestamp = true;
                          } else {
                            final previousItem = _chatItems[index - 1];
                            if (previousItem is MessageItem) {
                              showAvatarAndTimestamp =
                                  message.senderId !=
                                  previousItem.message.senderId;
                            } else {
                              showAvatarAndTimestamp = true;
                            }
                          }
                          return _buildMessageBubble(
                            message: message,
                            isMe: isMe,
                            showAvatarAndTimestamp: showAvatarAndTimestamp,
                          );
                        }
                        return const SizedBox.shrink();
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
    required bool showAvatarAndTimestamp,
  }) {
    // --- FIX APPLIED HERE ---
    final location = tz.getLocation('Asia/Kolkata');
    final istTime = tz.TZDateTime.from(message.timestamp, location);
    final formattedTime = DateFormat('HH:mm').format(istTime);

    final messageBubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? Colors.yellow : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message.text,
        style: GoogleFonts.poppins(color: isMe ? Colors.black : Colors.white),
      ),
    );
    final timestampText = Text(
      formattedTime,
      style: const TextStyle(color: Colors.white54, fontSize: 10),
    );
    final avatar = CircleAvatar(
      radius: 16,
      backgroundImage:
          message.senderImageUrl.isNotEmpty
              ? NetworkImage(message.senderImageUrl)
              : null,
      child:
          message.senderImageUrl.isEmpty
              ? const Icon(Icons.person, size: 16)
              : null,
    );
    final spacer = const SizedBox(width: 40);

    if (!isMe) {
      return Padding(
        padding: EdgeInsets.only(bottom: showAvatarAndTimestamp ? 8.0 : 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showAvatarAndTimestamp) avatar else spacer,
            const SizedBox(width: 8),
            Flexible(child: messageBubble),
            if (showAvatarAndTimestamp) ...[
              const SizedBox(width: 8),
              timestampText,
            ],
          ],
        ),
      );
    } else {
      return Padding(
        padding: EdgeInsets.only(bottom: showAvatarAndTimestamp ? 8.0 : 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showAvatarAndTimestamp) ...[
              timestampText,
              const SizedBox(width: 8),
            ],
            Flexible(child: messageBubble),
          ],
        ),
      );
    }
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
              icon: const Icon(Icons.send, color: Colors.yellow),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
