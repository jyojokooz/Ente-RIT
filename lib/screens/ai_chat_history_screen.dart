// ===============================
// FILE NAME: ai_chat_history_screen.dart
// FILE PATH: lib/screens/ai_chat_history_screen.dart
// ===============================

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

  // The signature Violet to Pink brand gradient
  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
    bool isDark,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF252528) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Chat?',
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to permanently delete the chat titled:',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "'$title'",
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting chat: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: Text(
            "Connect AI",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          backgroundColor: bgColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: Text(
            "You must be logged in to use Connect AI.",
            style: GoogleFonts.poppins(color: subtitleColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Connect AI",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),

      // --- STYLIZED GRADIENT FAB ---
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: _brandGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4B72).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToConversation(null),
          backgroundColor: Colors.transparent, // Let gradient show through
          elevation: 0, // Removes the default shadow so our custom glow works
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            "New Chat",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      ),

      body: StreamBuilder<List<AiConversation>>(
        stream: _chatAiService.getConversationsStream(_currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF9983F3)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(isDark, textColor, subtitleColor);
          }

          final conversations = snapshot.data!;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              100,
            ), // Bottom padding for FAB
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _navigateToConversation(conversation.id),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // --- GRADIENT ICON ---
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white10
                                      : Colors
                                          .grey
                                          .shade100, // Tinted background
                              shape: BoxShape.circle,
                            ),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return _brandGradient.createShader(bounds);
                              },
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white, // Required for ShaderMask
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // --- TEXT CONTENT ---
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conversation.title,
                                  style: GoogleFonts.poppins(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.yMMMd().add_jm().format(
                                    conversation.timestamp.toDate(),
                                  ),
                                  style: GoogleFonts.poppins(
                                    color: subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // --- DELETE BUTTON ---
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                            onPressed:
                                () => _showDeleteConfirmationDialog(
                                  conversation.id,
                                  conversation.title,
                                  isDark,
                                ),
                            tooltip: 'Delete Chat',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- MODERN EMPTY STATE ---
  Widget _buildEmptyState(bool isDark, Color textColor, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            ),
            child: ShaderMask(
              shaderCallback:
                  (Rect bounds) => _brandGradient.createShader(bounds),
              child: const Icon(
                Icons.forum_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No chats yet",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap 'New Chat' to start talking to Llama 3!",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: subtitleColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
