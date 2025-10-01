import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
// --- REVERTED CHANGE: Added google_generative_ai package back ---
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/chat_ai_service.dart';

// --- DATA MODEL (No changes) ---
enum MessageSource { app, web, chat, error }

class AiChatMessage {
  String text;
  final bool isUserMessage;
  MessageSource source;
  final Timestamp timestamp;

  AiChatMessage({
    required this.text,
    required this.isUserMessage,
    this.source = MessageSource.chat,
    required this.timestamp,
  });

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      text: map['text'] ?? '',
      isUserMessage: map['isUserMessage'] ?? false,
      source: MessageSource.values[map['source'] ?? MessageSource.chat.index],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUserMessage': isUserMessage,
      'source': source.index,
      'timestamp': timestamp,
    };
  }
}

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

  // --- REVERTED CHANGE: Using Gemini API Key from .env ---
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
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

  Future<void> _processAndSendMessage({String? prepopulatedMessage}) async {
    final userMessageText =
        prepopulatedMessage ?? _messageController.text.trim();
    if (userMessageText.isEmpty || _isResponding) return;

    _messageController.clear();
    setState(() {
      _isResponding = true;
    });

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

      final decision = await _getAiDecision(userMessageText);
      String? contextData;
      MessageSource responseSource = MessageSource.chat;

      if (decision == 'database_search') {
        contextData = await _fetchDatabaseContext(userMessageText);
        responseSource = MessageSource.app;
      } else if (decision == 'rit_kottayam_search') {
        contextData = await _fetchRITContext(userMessageText);
        responseSource = MessageSource.web;
      } else if (decision == 'web_search') {
        contextData = await _fetchWebContext(userMessageText);
        responseSource = MessageSource.web;
      }

      await _streamAiResponseToFirestore(
        conversationId,
        userMessageText,
        contextData,
        responseSource,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
        setState(() => _isResponding = false);
      }
    }
  }

  // --- REVERTED CHANGE: Switched back to google_generative_ai SDK for streaming ---
  Future<void> _streamAiResponseToFirestore(
    String conversationId,
    String userQuestion,
    String? context,
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

    try {
      if (context != null &&
          (context.startsWith("Error:") ||
              context.contains("unable to access"))) {
        await _chatAiService.updateMessageContent(
          _currentUser.uid,
          conversationId,
          messageRef.id,
          context,
        );
        return;
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: _geminiApiKey,
        systemInstruction: Content.system(
          "You are Connect AI, an advanced and professional assistant for the Kampus Konnect app. Your purpose is to provide accurate, helpful, and well-formatted information. Always use Markdown for formatting. You must be analytical and resourceful. When given context (like app data or web search results), your primary goal is to synthesize answers from it. If context is missing for specific questions (like a person's name), you may use your own knowledge but you MUST add a disclaimer that the information may be outdated.",
        ),
      );

      final prompt =
          "User's Question: '$userQuestion'.\n\nProvided Context:\n${context ?? 'No context provided.'}\n\n---\nYour Task:\n1.  First, analyze the user's question and correct any spelling mistakes to understand their true intent.\n2.  Formulate a professional and comprehensive answer based PRIMARILY on the 'Provided Context'.\n3.  If the context is insufficient to answer definitively (e.g., for names of specific people like a principal or professor), use your general knowledge to provide a likely answer.\n4.  **IMPORTANT**: If you use your general knowledge for information that can change over time (like names, dates, roles), you MUST include a friendly disclaimer, like 'Please note that this information is based on my last update and may have changed. It's always a good idea to verify on the official RIT Kottayam website.'\n5.  If you have no context and no general knowledge, simply state that you couldn't find the information.";

      final content = [Content.text(prompt)];
      final Stream<GenerateContentResponse> stream = model
          .generateContentStream(content);

      String streamedText = "";
      await for (var chunk in stream) {
        streamedText += chunk.text ?? "";
        await _chatAiService.updateMessageContent(
          _currentUser.uid,
          conversationId,
          messageRef.id,
          streamedText,
        );
      }
    } catch (e) {
      String errorText =
          e is GenerativeAIException
              ? "API Error: ${e.message}"
              : "I'm having trouble connecting.";
      await _chatAiService.updateMessageContent(
        _currentUser.uid,
        conversationId,
        messageRef.id,
        errorText,
      );
    } finally {
      if (mounted) {
        setState(() => _isResponding = false);
      }
    }
  }

  // --- REVERTED CHANGE: Switched back to google_generative_ai SDK for decision making ---
  Future<String> _getAiDecision(String userQuestion) async {
    if (_geminiApiKey.isEmpty) return 'chat';
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: _geminiApiKey,
      );
      final prompt =
          "You are an intelligent routing expert. The user's query may have spelling errors; your job is to classify their true INTENT into one of four categories: 'database_search', 'web_search', 'rit_kottayam_search', or 'chat'.\n\n- Use 'database_search' for queries about the user's own data in the app (e.g., 'my profile', 'my post', 'my connections', 'my name').\n- Use 'rit_kottayam_search' for ANY question related to the college, including 'RIT Kottayam', 'Rajiv Gandhi Institute of Technology', admissions, courses, principal, HOD, faculty, teachers, professors, or placements.\n- Use 'web_search' for general knowledge questions not about the user or the college (e.g., 'who is flutter's creator', 'latest tech news').\n- Use 'chat' for greetings, conversations, or anything that doesn't fit the other categories.\n\nRespond with ONLY ONE of the four category names. The user's query is: '$userQuestion'";
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final decision = response.text?.trim().toLowerCase() ?? 'chat';
      if ([
        'database_search',
        'web_search',
        'rit_kottayam_search',
        'chat',
      ].contains(decision)) {
        return decision;
      }
    } catch (e) {
      /* Fallback */
    }
    return 'chat';
  }

  // --- DATABASE AND WEB FETCHING (No changes needed) ---
  Future<String> _fetchDatabaseContext(String userMessageText) async {
    final lowerCaseMessage = userMessageText.toLowerCase();
    List<String> contextSnippets = [];

    if (lowerCaseMessage.contains('profile') ||
        lowerCaseMessage.contains('name') ||
        lowerCaseMessage.contains('bio') ||
        lowerCaseMessage.contains('department') ||
        lowerCaseMessage.contains('username')) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        contextSnippets.add(
          "User's Profile: Name is '${userData['displayName'] ?? 'Not set'}', Username is '@${userData['username'] ?? 'Not set'}', Bio is '${userData['bio'] ?? 'Not set'}', Department is '${userData['department'] ?? 'Not set'}'.",
        );
      }
    }
    if (lowerCaseMessage.contains('last post') ||
        lowerCaseMessage.contains('latest post') ||
        lowerCaseMessage.contains('recent post')) {
      final postQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUser.uid)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
      if (postQuery.docs.isNotEmpty) {
        final lastPost = postQuery.docs.first.data();
        final caption =
            lastPost['caption']?.isNotEmpty ?? false
                ? "'${lastPost['caption']}'"
                : "no caption";
        final likeCount = (lastPost['likes'] as List?)?.length ?? 0;
        final commentCount = lastPost['comments'] ?? 0;
        contextSnippets.add(
          "User's Last Post: The post with caption $caption has $likeCount likes and $commentCount comments.",
        );
      } else {
        contextSnippets.add(
          "User's Last Post: The user has not made any posts yet.",
        );
      }
    }
    if (lowerCaseMessage.contains('connection')) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      if (userDoc.exists) {
        final connectionCount =
            (userDoc.data()!['connections'] as List?)?.length ?? 0;
        contextSnippets.add(
          "User's Connections: The user currently has $connectionCount connections.",
        );
      }
    }

    return contextSnippets.isNotEmpty
        ? contextSnippets.join('\n')
        : 'No relevant app data found for the query.';
  }

  Future<String> _fetchRITContext(String userMessageText) async {
    if (_serperApiKey.isEmpty) {
      return "Error: Web search is not configured because the SERPER_API_KEY is missing.";
    }
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
              "No specific information found on the RIT Kottayam website for that query.";
        }
        return searchContext;
      } else {
        return "Error: Could not access the search API. Status code: ${response.statusCode}. Your API key might be invalid.";
      }
    } on TimeoutException {
      return "Error: The search request timed out. Please try again.";
    } on SocketException {
      return "Error: I was unable to access the RIT Kottayam website. Please check your internet connection.";
    } catch (e) {
      return "Error: An unexpected issue occurred while searching.";
    }
  }

  Future<String> _fetchWebContext(String userMessageText) async {
    if (_serperApiKey.isEmpty) {
      return "Error: Web search is not configured.";
    }
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
        return "Error: Could not access the search API. Status code: ${response.statusCode}.";
      }
    } on TimeoutException {
      return "Error: The web search request timed out.";
    } on SocketException {
      return "Error: Failed to perform web search. Please check your internet connection.";
    } catch (e) {
      return "Error: An unexpected issue occurred during the web search.";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_geminiApiKey.isEmpty) {
      return _buildErrorScaffold("Gemini API Key is not set!");
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
      body: Column(
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
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error: ${snapshot.error}",
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        final messages = snapshot.data ?? [];
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _scrollToBottom(),
                        );
                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16.0),
                          itemCount: messages.length + (_isResponding ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == messages.length) {
                              return const TypingIndicator();
                            }
                            final message = messages[index];
                            return AnimatedMessage(
                              child: _buildMessageBubble(message),
                            );
                          },
                        );
                      },
                    ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildIntroView() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 100,
              color: Colors.blue.shade200,
            ),
            const SizedBox(height: 24),
            Text(
              "How can I help you?",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Ask about your app data, the college, the web, or just have a chat.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionChip("Who is the principal of RIT Kottayam?"),
            _buildSuggestionChip("What are the stats on my last post?"),
            _buildSuggestionChip("Search for the latest news on Flutter"),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ActionChip(
        onPressed: () => _processAndSendMessage(prepopulatedMessage: text),
        backgroundColor: Colors.grey.shade800,
        avatar: Icon(Icons.auto_awesome, size: 16, color: Colors.blue.shade200),
        label: Text(text, style: GoogleFonts.poppins(color: Colors.white)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    final bool isMe = message.isUserMessage;
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final bubbleColor = isMe ? Colors.blue : const Color(0xFF2A2A2A);
    final borderRadius =
        isMe
            ? const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            );
    final bool isError =
        message.source == MessageSource.error ||
        message.text.startsWith("Error:") ||
        message.text.startsWith("API Error:");
    final errorColor = Colors.red[900]!.withAlpha(128);

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe && message.text.isNotEmpty)
          ContextLabel(source: message.source),
        Row(
          mainAxisAlignment: alignment,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              const CircleAvatar(
                backgroundColor: Color(0xFF2A2A2A),
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 20,
                  color: Colors.white70,
                ),
              ),
            if (!isMe) const SizedBox(width: 8),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: isError ? errorColor : bubbleColor,
                borderRadius: borderRadius,
              ),
              child: MarkdownBody(
                data: message.text.isEmpty ? " " : message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
            if (isMe) const SizedBox(width: 8),
            if (isMe)
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  _currentUser.displayName?.substring(0, 1).toUpperCase() ??
                      "U",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: const BoxDecoration(color: Color(0xFF1F1F1F)),
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
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                onSubmitted:
                    _isResponding ? null : (_) => _processAndSendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Colors.blue.shade200),
              onPressed: _isResponding ? null : () => _processAndSendMessage(),
            ),
          ],
        ),
      ),
    );
  }

  Scaffold _buildErrorScaffold(String error) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Configuration Error"),
        backgroundColor: const Color(0xFF1F1F1F),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "FATAL ERROR:\n$error\n\nMake sure you have a .env file in your project root with your API keys.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// --- ALL HELPER WIDGETS (TypingIndicator, ContextLabel, AnimatedMessage) remain unchanged ---
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    for (int i = 0; i < 3; i++) {
      _animations.add(
        Tween<double>(begin: 0, end: -8).animate(
          CurvedAnimation(parent: _controllers[i], curve: Curves.easeInOut),
        ),
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF2A2A2A),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 20,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _animations[index],
                  builder:
                      (context, child) => Transform.translate(
                        offset: Offset(0, _animations[index].value),
                        child: child,
                      ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade500,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class ContextLabel extends StatelessWidget {
  final MessageSource source;
  const ContextLabel({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    switch (source) {
      case MessageSource.web:
        text = 'Web Search';
        icon = Icons.public;
        break;
      case MessageSource.app:
        text = 'App Data';
        icon = Icons.storage;
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(left: 48, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedMessage extends StatefulWidget {
  final Widget child;
  const AnimatedMessage({super.key, required this.child});
  @override
  State<AnimatedMessage> createState() => _AnimatedMessageState();
}

class _AnimatedMessageState extends State<AnimatedMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _offsetAnimation, child: widget.child),
    );
  }
}
