import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../helpers/database_helper.dart';

class ChatMessage {
  final String senderId;
  final String text;
  final DateTime timestamp;
  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
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
  final String pusherAppKey = "582fafe5cbf4968bec2c";
  final String pusherAppCluster = "mt1";

  List<ChatMessage> _messages = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    List<String> ids = [_currentUser.uid, widget.receiverId];
    ids.sort();
    _chatRoomId = ids.join('_');
    _loadMessageHistoryAndInitPusher();
  }

  Future<void> _loadMessageHistoryAndInitPusher() async {
    final historyData = await DatabaseHelper.instance.getMessages(_chatRoomId);
    final historyMessages =
        historyData
            .map(
              (item) => ChatMessage(
                senderId: item['senderId'],
                text: item['text'],
                timestamp: DateTime.fromMillisecondsSinceEpoch(
                  item['timestamp'],
                ),
              ),
            )
            .toList();

    if (mounted) {
      setState(() {
        _messages = historyMessages;
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
      // --- FIX APPLIED HERE ---
      // The print statement has been removed.
      // In a real app, you might log this error to a service like Crashlytics.
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
                        return _buildMessageBubble(message.text, isMe);
                      },
                    ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? Colors.yellow : Colors.grey.shade800,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(color: isMe ? Colors.black : Colors.white),
          ),
        ),
      ],
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
              icon: const Icon(Icons.send, color: Colors.yellow),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
