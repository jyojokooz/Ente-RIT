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

abstract class ChatListItem {}

class MessageItem extends ChatListItem {
  // --- THIS IS THE FIX ---
  // The constructor and the field declaration are now separate, correct statements.
  MessageItem(this.message);
  final ChatMessage message;
}

class DateSeparatorItem extends ChatListItem {
  DateSeparatorItem(this.date);
  final DateTime date;
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

  final List<ChatListItem> _chatItems = [];
  bool _isLoadingHistory = true;
  String _currentUserImageUrl = '';
  final uuid = Uuid();

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

    for (var message in historyMessages) {
      _addMessageToList(message, isFromHistory: true);
    }

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
    }
  }

  void _addMessageToList(ChatMessage message, {bool isFromHistory = false}) {
    final location = tz.getLocation('Asia/Kolkata');
    DateTime? adjacentMessageDate;

    if (!isFromHistory && _chatItems.isNotEmpty) {
      final firstItem = _chatItems.first;
      if (firstItem is MessageItem) {
        adjacentMessageDate = firstItem.message.timestamp;
      }
    } else if (isFromHistory && _chatItems.isNotEmpty) {
      final lastItem = _chatItems.last;
      if (lastItem is MessageItem) {
        adjacentMessageDate = lastItem.message.timestamp;
      }
    }

    bool needsDateSeparator = true;
    if (adjacentMessageDate != null) {
      final adjacentLocalDate = tz.TZDateTime.from(
        adjacentMessageDate,
        location,
      );
      final newLocalDate = tz.TZDateTime.from(message.timestamp, location);
      if (adjacentLocalDate.day == newLocalDate.day &&
          adjacentLocalDate.month == newLocalDate.month &&
          adjacentLocalDate.year == newLocalDate.year) {
        needsDateSeparator = false;
      }
    }

    if (isFromHistory) {
      if (needsDateSeparator) {
        _chatItems.add(DateSeparatorItem(message.timestamp));
      }
      _chatItems.add(MessageItem(message));
    } else {
      if (needsDateSeparator) {
        _chatItems.insert(0, DateSeparatorItem(message.timestamp));
      }
      _chatItems.insert(0, MessageItem(message));
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
            _addMessageToList(newMessage);
          });
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

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
      _addMessageToList(message);
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
        _chatItems.removeWhere(
          (item) => item is MessageItem && item.message.id == messageId,
        );
      });
    }
  }

  void _showDeleteDialog(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
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
        );
      },
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
                          return GestureDetector(
                            onLongPress: () {
                              if (isMe) {
                                _showDeleteDialog(message.id);
                              }
                            },
                            child: _buildMessageBubble(
                              message: message,
                              isMe: isMe,
                              showAvatarAndTimestamp: showAvatarAndTimestamp,
                            ),
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
