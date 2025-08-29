import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/chat_ai_service.dart';
import 'ai_chat_screen.dart';

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

  Future<void> _showDeleteConfirmationDialog(
    String conversationId,
    String title,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: Text(
            'Delete Chat?',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to permanently delete the chat titled:',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  "'$title'",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                // --- FIX: Replaced deprecated withOpacity with withAlpha ---
                backgroundColor: Colors.red.shade900.withAlpha(
                  (255 * 0.8).round(),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteConversation(conversationId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      await _chatAiService.deleteConversation(
        _currentUser!.uid,
        conversationId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chat deleted successfully."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting chat: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Text(
            "Connect AI",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1F1F1F),
        ),
        body: Center(
          child: Text(
            "You must be logged in to use Connect AI.",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          "Connect AI",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToConversation(null),
        label: Text(
          "New Chat",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade300,
      ),
      body: StreamBuilder<List<AiConversation>>(
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

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder:
                (context, index) => Divider(
                  color: Colors.grey.shade800,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
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
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.grey[600]),
                  onPressed: () {
                    _showDeleteConfirmationDialog(
                      conversation.id,
                      conversation.title,
                    );
                  },
                  tooltip: 'Delete Chat',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
