import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AiChatMessage {
  final String text;
  final bool isUserMessage;
  AiChatMessage({required this.text, required this.isUserMessage});
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final List<AiChatMessage> _messages = [];
  bool _isTyping = false;

  static const _apiKey = String.fromEnvironment('OPENROUTER_API_KEY');

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // final scaffoldMessenger = ScaffoldMessenger.of(context); // <-- FIX: REMOVED THIS LINE

    _messageController.clear();
    setState(() {
      _messages.insert(0, AiChatMessage(text: text, isUserMessage: true));
      _isTyping = true;
    });

    final conversationHistory =
        _messages.reversed.map((msg) {
          return {
            "role": msg.isUserMessage ? "user" : "assistant",
            "content": msg.text,
          };
        }).toList();

    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://yourapp.com",
          "X-Title": "Kampus Konnect",
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct:free",
          "messages": conversationHistory,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            AiChatMessage(text: aiResponse.trim(), isUserMessage: false),
          );
        });
      } else {
        final error = jsonDecode(response.body)['error']['message'];
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            AiChatMessage(text: "Error: $error", isUserMessage: false),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.insert(
            0,
            AiChatMessage(
              text: "Failed to connect. Please check your internet connection.",
              isUserMessage: false,
            ),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKey.isEmpty) {
      return _buildErrorScaffold("OpenRouter API Key is not set!");
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("AI Assistant", style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == 0) {
                  return _buildMessageBubble("AI is typing...", false);
                }
                final message = _messages[_isTyping ? index - 1 : index];
                return _buildMessageBubble(message.text, message.isUserMessage);
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Scaffold _buildErrorScaffold(String error) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Configuration Error"),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "FATAL ERROR:\n$error\n\nMake sure you run the app with the --dart-define flag:\nflutter run --dart-define=OPENROUTER_API_KEY=YOUR_KEY",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? Colors.yellow : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: isMe ? Colors.black : Colors.white,
            ),
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
                  hintText: 'Ask me anything...',
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
                onSubmitted: (_) => _sendMessage(),
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
