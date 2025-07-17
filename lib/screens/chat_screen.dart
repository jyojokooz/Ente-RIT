import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // <-- Import for date formatting
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../helpers/database_helper.dart';

// --- Message Model ---
class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final String senderImageUrl; // <-- ADDED: To hold the image URL

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
  final String pusherAppKey = "582fafe5cbf4968bec2c"; // Replace with your key
  final String pusherAppCluster = "mt1"; // Replace with your cluster

  List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;
  String _currentUserImageUrl = ''; // Store current user's image URL

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUser.uid, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');
    _loadDataAndInitPusher();
  }

  // Combines loading history and user data
  Future<void> _loadDataAndInitPusher() async {
    // 1. Get current user's image URL from Firestore (or wherever you store it)
    // This is a placeholder. You should fetch this from your 'users' collection.
    _currentUserImageUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';

    // 2. Load message history from local DB
    final historyData = await DatabaseHelper.instance.getMessages(_chatRoomId);
    final historyMessages =
        historyData.map((item) {
          final isMe = item['senderId'] == _currentUser.uid;
          return ChatMessage(
            senderId: item['senderId'],
            text: item['text'],
            timestamp: DateTime.fromMillisecondsSinceEpoch(item['timestamp']),
            // Assign the correct image URL based on who the sender is
            senderImageUrl:
                isMe ? _currentUserImageUrl : widget.receiverImageUrl,
          );
        }).toList();

    if (mounted) {
      setState(() {
        _messages = historyMessages;
        _isLoadingHistory = false;
      });
    }

    // 3. Connect to Pusher
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

  void _onPusherEvent(PusherEvent event) {
    if (event.eventName == 'client-new-message') {
      final data = jsonDecode(event.data);
      if (data['senderId'] != _currentUser.uid) {
        final newMessage = ChatMessage(
          senderId: data['senderId'],
          text: data['text'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
          senderImageUrl:
              widget.receiverImageUrl, // The sender is the other person
        );

        DatabaseHelper.instance.insertMessage({
          'chatRoomId': _chatRoomId,
          'senderId': newMessage.senderId,
          'text': newMessage.text,
          'timestamp': newMessage.timestamp.millisecondsSinceEpoch,
        });

        if (mounted) {
          setState(() {
            _messages.insert(0, newMessage);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    pusher.unsubscribe(channelName: 'private-$_chatRoomId');
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      senderId: _currentUser.uid,
      text: text,
      timestamp: DateTime.now(),
      senderImageUrl: _currentUserImageUrl, // Include our own image URL
    );

    _messageController.clear();
    setState(() {
      _messages.insert(0, message);
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
                    : _messages.isEmpty
                    ? Center(
                      child: Text(
                        'Say hello!',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMe = message.senderId == _currentUser.uid;
                        // Pass the full message object to the builder
                        return _buildMessageBubble(message, isMe);
                      },
                    ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  // --- THIS WIDGET IS NOW UPDATED ---
  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    // Format the timestamp
    final String formattedTime = DateFormat('h:mm a').format(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Show avatar for the other person
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                radius: 15,
                backgroundImage:
                    message.senderImageUrl.isNotEmpty
                        ? NetworkImage(message.senderImageUrl)
                        : null,
                child:
                    message.senderImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 15)
                        : null,
              ),
            ),

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // The message bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.yellow : Colors.grey.shade800,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          isMe
                              ? const Radius.circular(20)
                              : const Radius.circular(2),
                      bottomRight:
                          isMe
                              ? const Radius.circular(2)
                              : const Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(color: isMe ? Colors.black : Colors.white),
                  ),
                ),
                // The timestamp below the bubble
                Padding(
                  padding: const EdgeInsets.only(
                    top: 4.0,
                    left: 8.0,
                    right: 8.0,
                  ),
                  child: Text(
                    formattedTime,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // Show avatar for yourself
          if (isMe)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: CircleAvatar(
                radius: 15,
                backgroundImage:
                    message.senderImageUrl.isNotEmpty
                        ? NetworkImage(message.senderImageUrl)
                        : null,
                child:
                    message.senderImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 15)
                        : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInputField() {
    // This widget is unchanged
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
