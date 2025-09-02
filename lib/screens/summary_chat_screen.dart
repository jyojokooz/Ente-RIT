// lib/screens/summary_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/youtube_summarizer_service.dart';

class SummaryChatScreen extends StatefulWidget {
  final String initialSummary;
  final String videoTitle;

  const SummaryChatScreen({
    super.key,
    required this.initialSummary,
    required this.videoTitle,
  });

  @override
  State<SummaryChatScreen> createState() => _SummaryChatScreenState();
}

class _SummaryChatScreenState extends State<SummaryChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final YouTubeSummarizerService _summarizerService =
      YouTubeSummarizerService();

  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start the chat with the initial summary from the AI
    _chatHistory.add({'role': 'ai', 'message': widget.initialSummary});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _chatHistory.add({'role': 'user', 'message': userMessage});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final aiResponse = await _summarizerService.getFollowUpAnswer(
        summaryContext: widget.initialSummary,
        videoTitle: widget.videoTitle,
        userQuestion: userMessage,
      );
      setState(() {
        _chatHistory.add({'role': 'ai', 'message': aiResponse});
      });
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'role': 'ai',
          'message': 'Sorry, I encountered an error: ${e.toString()}',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Chat about "${widget.videoTitle}"',
          style: GoogleFonts.poppins(),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                return _ChatMessageBubble(
                  message: message['message']!,
                  isUser: isUser,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(color: Colors.yellow),
            ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: Colors.grey.shade900,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Elaborate on a key point...',
                  hintStyle: TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.grey.shade800,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.yellow),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  const _ChatMessageBubble({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isUser ? Colors.yellow : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
