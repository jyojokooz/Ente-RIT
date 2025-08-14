import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

class AiChatMessage {
  String text;
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
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  bool _isResponding = false;

  final String _openRouterApiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  final String _serperApiKey = dotenv.env['SERPER_API_KEY'] ?? '';
  final _currentUser = FirebaseAuth.instance.currentUser!;

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
          _scrollController.position.minScrollExtent,
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
      _messages.insert(
        0,
        AiChatMessage(text: userMessageText, isUserMessage: true),
      );
      _messages.insert(0, AiChatMessage(text: "", isUserMessage: false));
      _isResponding = true;
    });
    _scrollToBottom();

    final decision = await _getAiDecision(userMessageText);
    String? contextData;

    if (decision == 'database_search') {
      contextData = await _fetchDatabaseContext(userMessageText);
    } else if (decision == 'web_search') {
      contextData = await _fetchWebContext(userMessageText);
    }

    await _getAiStreamingResponse(userMessageText, contextData);
  }

  Future<String> _getAiDecision(String userQuestion) async {
    if (_openRouterApiKey.isEmpty) {
      return 'chat';
    }
    try {
      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_openRouterApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct:free",
          "messages": [
            {
              "role": "system",
              "content":
                  "You are a routing expert. Your job is to classify the user's query into one of three categories: 'database_search', 'web_search', or 'chat'. Keywords for 'database_search' include 'my profile', 'my post', 'connections', 'my name', 'my stats'. Keywords for 'web_search' include 'who is', 'what is', 'search for', 'find information on'. For anything else, like greetings or general conversation, respond with 'chat'. Respond with ONLY ONE of these three category names and nothing else.",
            },
            {"role": "user", "content": userQuestion},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final decision =
            jsonDecode(
              response.body,
            )['choices'][0]['message']['content'].trim().toLowerCase();
        if (['database_search', 'web_search', 'chat'].contains(decision)) {
          return decision;
        }
      }
    } catch (e) {
      /* Fallback */
    }
    return 'chat';
  }

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
    if (lowerCaseMessage.contains('total post') ||
        lowerCaseMessage.contains('how many posts')) {
      final postQuery =
          await FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: _currentUser.uid)
              .get();
      contextSnippets.add(
        "User's Total Posts: The user has made a total of ${postQuery.docs.length} posts.",
      );
    }

    return contextSnippets.isNotEmpty
        ? contextSnippets.join('\n')
        : 'No relevant app data found for the query.';
  }

  Future<String> _fetchWebContext(String userMessageText) async {
    if (_serperApiKey.isEmpty) {
      return "Web search is not configured because the SERPER_API_KEY is missing.";
    }
    try {
      final response = await http.post(
        Uri.parse("https://google.serper.dev/search"),
        headers: {
          'X-API-KEY': _serperApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'q': userMessageText}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String searchContext = "Here are some top web search results:\n";
        if (data['organic'] != null && data['organic'].isNotEmpty) {
          int count = 0;
          for (var result in data['organic']) {
            if (count < 3) {
              searchContext +=
                  "Title: ${result['title']}\nSnippet: ${result['snippet']}\n\n";
              count++;
            }
          }
        } else {
          searchContext = "No web search results were found for that query.";
        }
        return searchContext;
      }
    } catch (e) {
      /* Fallback */
    }
    return "Failed to perform web search due to a network error.";
  }

  Future<void> _getAiStreamingResponse(
    String userQuestion,
    String? context,
  ) async {
    final messagesForApi = [
      {
        "role": "system",
        "content":
            "You are a friendly and helpful assistant for a campus social app called Kampus Konnect. Your name is Tom. You MUST format your responses using Markdown (e.g., use **bold** for emphasis, `code blocks` for code, and lists for steps). When context is provided, you MUST base your answer ONLY on that context.",
      },
      {
        "role": "user",
        "content":
            "My question is: '$userQuestion'.\n\nHere is some context to help you answer:\n${context ?? 'No specific context provided. You can chat normally.'}",
      },
    ];

    try {
      final request = http.Request(
        "POST",
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      );
      request.headers.addAll({
        "Authorization": "Bearer $_openRouterApiKey",
        "Content-Type": "application/json",
      });
      request.body = jsonEncode({
        "model":
            "deepseek/deepseek-chat", // Using a high-quality free DeepSeek model
        "messages": messagesForApi,
        "stream": true,
      });

      final response = await request.send();

      response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith("data: ")) {
                final dataString = line.substring(6);
                if (dataString == "[DONE]") return;
                try {
                  final data = jsonDecode(dataString);
                  final delta = data['choices'][0]['delta'];
                  if (delta != null && delta['content'] != null) {
                    final textChunk = delta['content'];
                    if (mounted) {
                      setState(() => _messages.first.text += textChunk);
                      _scrollToBottom();
                    }
                  }
                } catch (e) {
                  /* Ignore parsing errors for incomplete chunks */
                }
              }
            },
            onDone: () {
              if (mounted) {
                setState(() => _isResponding = false);
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _messages.first.text =
                      "Sorry, an error occurred while streaming the response.";
                  _isResponding = false;
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.first.text =
              "I'm having trouble connecting. Please check your internet.";
          _isResponding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_openRouterApiKey.isEmpty) {
      return _buildErrorScaffold("OpenRouter API Key is not set!");
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "AI Assistant",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _messages.isEmpty && !_isResponding
                    ? _buildIntroView()
                    : ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return AnimatedMessage(
                          child: _buildMessageBubble(message),
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
            Image.asset(
              'assets/ai_character.png',
              height: 150,
              color: Colors.white70,
              errorBuilder:
                  (c, e, s) => const Icon(
                    Icons.smart_toy_outlined,
                    size: 120,
                    color: Colors.blueGrey,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              "Hey there!",
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "I'm your personal assistant.\nAsk about your app data or search the web!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildSuggestionChip("What are the stats on my last post?"),
            _buildSuggestionChip("Search for the latest news on Flutter"),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      onPressed: () => _processAndSendMessage(prepopulatedMessage: text),
      backgroundColor: Colors.grey.shade800,
      avatar: const Icon(Icons.auto_awesome, size: 16, color: Colors.yellow),
      label: Text(text, style: GoogleFonts.poppins(color: Colors.white)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: Colors.grey.shade700),
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
            "FATAL ERROR:\n$error\n\nMake sure you have a .env file in your project root with your API keys.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AiChatMessage message) {
    final bool isMe = message.isUserMessage;
    final bool isTyping = !isMe && message.text.isEmpty && _isResponding;

    final markdownStyle = MarkdownStyleSheet.fromTheme(
      Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: isMe ? Colors.black : Colors.white,
          displayColor: isMe ? Colors.black : Colors.white,
        ),
      ),
    ).copyWith(
      p: GoogleFonts.poppins(fontSize: 15),
      code: GoogleFonts.robotoMono(
        backgroundColor:
            isMe ? Colors.black.withAlpha(25) : Colors.white.withAlpha(25),
      ),
      codeblockDecoration: BoxDecoration(
        color: isMe ? Colors.black.withAlpha(25) : Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      listBullet: GoogleFonts.poppins(),
      h1: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      h2: GoogleFonts.poppins(fontWeight: FontWeight.bold),
    );

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
          child:
              isTyping
                  ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  )
                  : MarkdownBody(
                    data: message.text.isEmpty ? " " : message.text,
                    selectable: true,
                    styleSheet: markdownStyle,
                  ),
        ),
      ],
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
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
                onSubmitted: (_) => _processAndSendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.yellow),
              onPressed: () => _processAndSendMessage(),
            ),
          ],
        ),
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
