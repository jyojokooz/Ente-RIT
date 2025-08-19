import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/chat_ai_service.dart';
import 'ai_chat_screen.dart'; // This is our refactored conversation screen

class AiChatHistoryScreen extends StatefulWidget {
  const AiChatHistoryScreen({super.key});

  @override
  State<AiChatHistoryScreen> createState() => _AiChatHistoryScreenState();
}

class _AiChatHistoryScreenState extends State<AiChatHistoryScreen> {
  final ChatAiService _chatAiService = ChatAiService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  void _navigateToConversation(String? conversationId) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AiConversationScreen(conversationId: conversationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Text(
            "AI Assistant",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1F1F1F),
        ),
        body: Center(
          child: Text(
            "You must be logged in to use the AI Assistant.",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "AI Assistant",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToConversation(null), // Start a new chat
        label: Text(
          "New Chat",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade300,
      ),
      body: StreamBuilder<List<AiConversation>>(
        // --- FIX: Removed the unnecessary '!' from _currentUser ---
        stream: _chatAiService.getConversationsStream(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No chats yet.\nTap 'New Chat' to start!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white70,
                ),
                title: Text(
                  conversation.title,
                  style: GoogleFonts.poppins(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat.yMMMd().add_jm().format(
                    conversation.timestamp.toDate(),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                onTap: () => _navigateToConversation(conversation.id),
              );
            },
          );
        },
      ),
    );
  }
}
