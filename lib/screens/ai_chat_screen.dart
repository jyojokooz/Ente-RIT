// ===============================
// FILE PATH: lib/screens/ai_chat_screen.dart
// ===============================

import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../models/ai_chat_message.dart';
import '../services/chat_ai_service.dart';
import '../widgets/chat/ai_chat_components.dart';

class AiConversationScreen extends StatefulWidget {
  final String? conversationId;
  const AiConversationScreen({super.key, this.conversationId});

  @override
  State<AiConversationScreen> createState() => _AiConversationScreenState();
}

class _AiConversationScreenState extends State<AiConversationScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatAiService _chatAiService = ChatAiService();

  bool _isResponding = false;
  String? _currentConversationId;

  String? _streamingMessageId;
  String _streamingText = "";
  MessageSource _streamingSource = MessageSource.chat;

  final String _workerUrl = dotenv.env['CLOUDFLARE_WORKER_URL'] ?? '';
  final String _serperApiKey = dotenv.env['SERPER_API_KEY'] ?? '';
  final _currentUser = FirebaseAuth.instance.currentUser!;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  // --- RAG FIX: ROBUST ACCOUNT DATA FETCHER ---
  // This builds a comprehensive context string about the user so the AI answers perfectly.
  Future<String> _buildRobustUserContext() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      final userData = userDoc.data() ?? {};

      final postQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUser.uid)
              .orderBy('timestamp', descending: true)
              .limit(3)
              .get();

      final postCountSnapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUser.uid)
              .count()
              .get();
      int postCount = postCountSnapshot.count ?? 0;

      String context = "SYSTEM CONTEXT - CURRENT USER DATA:\n";
      context +=
          "You are talking to this exact user. Answer queries about them using this data:\n";
      context += "- Name: ${userData['displayName'] ?? 'Not set'}\n";
      context += "- Username: @${userData['username'] ?? 'Not set'}\n";
      context += "- Email: ${userData['email'] ?? 'Not set'}\n";
      context += "- Role: ${userData['role'] ?? 'Student'}\n";
      context += "- Department: ${userData['department'] ?? 'Not set'}\n";
      context +=
          "- Bio: ${userData['bio'] != null && userData['bio'].toString().isNotEmpty ? userData['bio'] : 'No bio set'}\n";
      context += "- Current Status: ${userData['status'] ?? 'No status'}\n";
      context +=
          "- Connections (Friends): ${(userData['connections'] as List?)?.length ?? 0}\n";
      context += "- Total Posts Created: $postCount\n";

      if (postQuery.docs.isNotEmpty) {
        context += "\nRecent Posts by User:\n";
        for (var doc in postQuery.docs) {
          final p = doc.data();
          context +=
              " • \"${p['caption']}\" (Likes: ${(p['likes'] as List?)?.length ?? 0}, Comments: ${p['comments'] ?? 0})\n";
        }
      } else {
        context += "\nRecent Posts: User has not posted anything yet.\n";
      }
      return context;
    } catch (e) {
      return "Failed to load user database context.";
    }
  }

  Future<void> _processAndSendMessage({String? prepopulatedMessage}) async {
    final userMessageText =
        prepopulatedMessage ?? _messageController.text.trim();
    if (userMessageText.isEmpty || _isResponding) return;

    _messageController.clear();
    setState(() => _isResponding = true);

    final userMessage = AiChatMessage(
      text: userMessageText,
      isUserMessage: true,
      timestamp: Timestamp.now(),
    );

    String conversationId = _currentConversationId ?? '';

    try {
      if (conversationId.isEmpty) {
        final newId = await _chatAiService.createConversation(
          _currentUser.uid,
          userMessage,
        );
        if (mounted) {
          setState(() {
            _currentConversationId = newId;
            conversationId = newId;
          });
        }
      } else {
        await _chatAiService.addMessage(
          _currentUser.uid,
          conversationId,
          userMessage,
        );
      }

      String? contextData;
      MessageSource responseSource = MessageSource.chat;

      // --- RAG FIX: KEYWORD TRIGGER ---
      // Force database context if user asks about themselves, avoiding unreliable LLM routing
      final isAccountQuery = RegExp(
        r'\b(my|i|me|mine|profile|account|post|posts|name|username|department|bio|friends|connections)\b',
        caseSensitive: false,
      ).hasMatch(userMessageText.toLowerCase());

      if (isAccountQuery) {
        contextData = await _buildRobustUserContext();
        responseSource = MessageSource.app;
      } else {
        // Fallback to external routing if it's not an account query
        final decision = await _getAiDecision(userMessageText);
        if (decision == 'rit_kottayam_search') {
          contextData = await _fetchRITContext(userMessageText);
          responseSource = MessageSource.web;
        } else if (decision == 'web_search') {
          contextData = await _fetchWebContext(userMessageText);
          responseSource = MessageSource.web;
        }
      }

      // Always inject basic identity so the AI knows who it is talking to
      final basicIdentity =
          "\n[System: The user speaking to you is named ${_currentUser.displayName}].";
      contextData = (contextData ?? "") + basicIdentity;

      await _streamAiResponse(
        conversationId,
        userMessageText,
        contextData,
        responseSource,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isResponding = false);
      }
    }
  }

  Future<void> _streamAiResponse(
    String conversationId,
    String userQuestion,
    String? contextData,
    MessageSource source,
  ) async {
    final placeholderMessage = AiChatMessage(
      text: "",
      isUserMessage: false,
      source: source,
      timestamp: Timestamp.now(),
    );

    final messageRef = await _chatAiService.addMessage(
      _currentUser.uid,
      conversationId,
      placeholderMessage,
    );

    setState(() {
      _streamingMessageId = messageRef.id;
      _streamingText = "";
      _streamingSource = source;
    });

    try {
      if (contextData != null &&
          (contextData.startsWith("Error:") ||
              contextData.contains("unable to access"))) {
        setState(() => _streamingText = contextData!);
        await _chatAiService.updateMessageContent(
          _currentUser.uid,
          conversationId,
          messageRef.id,
          contextData,
        );
        return;
      }

      final request =
          http.Request('POST', Uri.parse(_workerUrl))
            ..headers['Content-Type'] = 'application/json'
            ..body = jsonEncode({
              'type': 'chat',
              'query': userQuestion,
              'context': contextData ?? '',
            });

      final client = http.Client();
      final response = await client.send(request);

      String accumulatedText = "";

      await for (var chunk in response.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ') && line != 'data: [DONE]') {
            final dataStr = line.substring(6);
            try {
              final dataJson = jsonDecode(dataStr);
              if (dataJson['response'] != null) {
                accumulatedText += dataJson['response'];
                setState(() => _streamingText = accumulatedText);
                _scrollToBottom();
              }
            } catch (_) {}
          }
        }
      }

      await _chatAiService.updateMessageContent(
        _currentUser.uid,
        conversationId,
        messageRef.id,
        accumulatedText,
      );
    } catch (e) {
      final err = "Connection lost to the neural network. Please try again.";
      setState(() => _streamingText = err);
      await _chatAiService.updateMessageContent(
        _currentUser.uid,
        conversationId,
        messageRef.id,
        err,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResponding = false;
          _streamingMessageId = null;
        });
      }
    }
  }

  Future<String> _getAiDecision(String userQuestion) async {
    try {
      final response = await http.post(
        Uri.parse(_workerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': 'route', 'query': userQuestion}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final decision =
            data['route']?.toString().trim().toLowerCase() ?? 'chat';
        if (['web_search', 'rit_kottayam_search', 'chat'].contains(decision)) {
          return decision;
        }
      }
    } catch (_) {}
    return 'chat';
  }

  Future<String> _fetchRITContext(String userMessageText) async {
    if (_serperApiKey.isEmpty)
      return "Error: Web search is missing SERPER_API_KEY.";
    try {
      final searchQuery =
          "$userMessageText Rajiv Gandhi Institute of Technology Kottayam site:https://www.rit.ac.in/";
      final response = await http
          .post(
            Uri.parse("https://google.serper.dev/search"),
            headers: {
              'X-API-KEY': _serperApiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'q': searchQuery}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String searchContext = "Web search results from rit.ac.in:\n";
        if (data['organic'] != null && data['organic'].isNotEmpty) {
          int count = 0;
          for (var result in data['organic']) {
            if (count < 5) {
              searchContext +=
                  "Title: ${result['title']}\nSnippet: ${result['snippet']}\n\n";
              count++;
            }
          }
        } else {
          searchContext =
              "No specific information found on the RIT Kottayam website.";
        }
        return searchContext;
      } else {
        return "Error: Could not access the search API.";
      }
    } catch (e) {
      return "Error: Unexpected issue searching the web.";
    }
  }

  Future<String> _fetchWebContext(String userMessageText) async {
    if (_serperApiKey.isEmpty) return "Error: Web search is not configured.";
    try {
      final response = await http
          .post(
            Uri.parse("https://google.serper.dev/search"),
            headers: {
              'X-API-KEY': _serperApiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'q': userMessageText}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String searchContext = "General web search results:\n";
        if (data['organic'] != null && data['organic'].isNotEmpty) {
          int count = 0;
          for (var result in data['organic']) {
            if (count < 5) {
              searchContext +=
                  "Title: ${result['title']}\nSnippet: ${result['snippet']}\n\n";
              count++;
            }
          }
        } else {
          searchContext = "No web search results were found.";
        }
        return searchContext;
      } else {
        return "Error: Could not access the search API.";
      }
    } catch (e) {
      return "Error: An unexpected issue occurred during the web search.";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_workerUrl.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0C),
        body: Center(
          child: Text(
            "FATAL ERROR: Cloudflare Worker URL missing.",
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C), // Deep premium dark background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: const Color(0xFF0A0A0C).withOpacity(0.6)),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4B72).withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Connect AI",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/mesh_bg.png',
            ), // Optional: Add a dark mesh background in your assets
            fit: BoxFit.cover,
            opacity: 0.05,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child:
                  _currentConversationId == null
                      ? _buildIntroView()
                      : StreamBuilder<List<AiChatMessage>>(
                        stream: _chatAiService.getMessagesStream(
                          _currentUser.uid,
                          _currentConversationId!,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF9983F3),
                              ),
                            );
                          }

                          List<AiChatMessage> messages =
                              snapshot.data?.toList() ?? [];
                          if (_streamingMessageId != null) {
                            final index = messages.indexWhere(
                              (m) => m.timestamp.nanoseconds == 0,
                            );
                            if (index != -1) {
                              messages[index].text = _streamingText;
                              messages[index].source = _streamingSource;
                            }
                          }

                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _scrollToBottom(),
                          );

                          return ListView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              top: 100.0,
                              bottom: 20.0,
                            ),
                            itemCount:
                                messages.length +
                                (_isResponding && _streamingMessageId == null
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index == messages.length)
                                return const AiTypingIndicator();
                              return AiAnimatedMessage(
                                child: AiChatBubble(message: messages[index]),
                              );
                            },
                          );
                        },
                      ),
            ),
            AiChatInputBar(
              controller: _messageController,
              isResponding: _isResponding,
              onSend: _processAndSendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            // Glowing Orb
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9983F3).withOpacity(0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "How can I help you today?",
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "I can answer questions about your account, search the RIT website, or chat about anything.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(
                  "What is my current role and department?",
                  Icons.person,
                ),
                _buildSuggestionChip(
                  "Summarize my recent posts.",
                  Icons.grid_view_rounded,
                ),
                _buildSuggestionChip(
                  "Who is the principal of RIT?",
                  Icons.school,
                ),
                _buildSuggestionChip(
                  "Search the web for Flutter news.",
                  Icons.public,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon) {
    return ActionChip(
      onPressed: () => _processAndSendMessage(prepopulatedMessage: text),
      backgroundColor: Colors.white.withOpacity(0.05),
      avatar: Icon(icon, size: 16, color: const Color(0xFF9983F3)),
      label: Text(text, style: GoogleFonts.poppins(color: Colors.white)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
