// ===============================
// FILE NAME: summary_chat_screen.dart
// FILE PATH: lib/screens/summary_chat_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/tools/youtube_summarizer/youtube_summarizer_service.dart';

/// A screen for a conversational chat with an AI about a video summary.
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
    _chatHistory.add({'role': 'ai', 'message': widget.initialSummary});
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _summarizerService.close();
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
      final aiResponse = await _summarizerService.getWebEnhancedAnswer(
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
      backgroundColor: Colors.white, // Modern White Background
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video Chat',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              widget.videoTitle,
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _chatHistory.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chatHistory.length) {
                  return const _TypingIndicatorBubble();
                }
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                return _ChatMessageBubble(
                  message: message['message']!,
                  isUser: isUser,
                );
              },
            ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Ask for details...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _isLoading ? null : (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black, // Modern black button
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, color: Colors.white),
                onPressed: _isLoading ? null : _sendMessage,
              ),
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
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
      bottomRight:
          isUser ? const Radius.circular(4) : const Radius.circular(20),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          // User: Primary Yellow (App Theme) or Black for high contrast.
          // Let's use Yellow for user to match main app, Light Grey for AI.
          color: isUser ? Colors.yellow : Colors.grey[100],
          borderRadius: borderRadius,
          border: isUser ? null : Border.all(color: Colors.grey[200]!),
        ),
        child: MarkdownBody(
          data: message,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.poppins(
              color: Colors.black87, // Always black text for readability
              fontSize: 15,
              height: 1.5,
            ),
            h3: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            strong: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            listBullet: GoogleFonts.poppins(color: Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: SizedBox(
          width: 24,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
