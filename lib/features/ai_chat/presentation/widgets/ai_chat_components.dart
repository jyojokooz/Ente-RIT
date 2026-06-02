// ===============================
// FILE PATH: lib/widgets/chat/ai_chat_components.dart
// ===============================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/ai_chat/domain/ai_chat_message.dart';

// --- 1. AI CHAT BUBBLE ---
class AiChatBubble extends StatelessWidget {
  final AiChatMessage message;

  const AiChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isUserMessage;
    final alignment = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    final borderRadius =
        isMe
            ? const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(6),
            )
            : const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(6),
            );

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isMe &&
            message.text.isNotEmpty &&
            message.source != MessageSource.chat)
          AiContextLabel(source: message.source),

        Row(
          mainAxisAlignment: alignment,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              Container(
                margin: const EdgeInsets.only(right: 12, bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4B72).withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.white,
                ),
              ),

            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isMe
                          ? const LinearGradient(
                            colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                          )
                          : null,
                  color:
                      isMe
                          ? null
                          : const Color(0xFF1E1E24), // Premium dark gray
                  border:
                      isMe
                          ? null
                          : Border.all(color: Colors.white.withOpacity(0.05)),
                  borderRadius: borderRadius,
                  boxShadow: [
                    if (isMe)
                      BoxShadow(
                        color: const Color(0xFFFF4B72).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: MarkdownBody(
                  data: message.text.isEmpty ? " " : message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.6,
                    ),
                    h1: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    h3: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    listBullet: GoogleFonts.poppins(color: Colors.white),
                    code: GoogleFonts.firaCode(
                      backgroundColor: Colors.black45,
                      color: const Color(0xFF00C6FB), // Cyan code
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --- 2. AI INPUT BAR ---
class AiChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isResponding;
  final VoidCallback onSend;

  const AiChatInputBar({
    super.key,
    required this.controller,
    required this.isResponding,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Ask Connect AI...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white30),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: isResponding ? null : (_) => onSend(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isResponding ? null : onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient:
                        isResponding
                            ? null
                            : const LinearGradient(
                              colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
                            ),
                    color: isResponding ? Colors.white10 : null,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!isResponding)
                        BoxShadow(
                          color: const Color(0xFFFF4B72).withOpacity(0.4),
                          blurRadius: 12,
                        ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. CONTEXT LABEL PILL ---
class AiContextLabel extends StatelessWidget {
  final MessageSource source;
  const AiContextLabel({super.key, required this.source});

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    Color color;

    switch (source) {
      case MessageSource.web:
        text = 'Searched Web';
        icon = Icons.public;
        color = const Color(0xFF00C6FB);
        break;
      case MessageSource.app:
        text = 'Read App Data';
        icon = Icons.storage_rounded;
        color = const Color(0xFF43E97B);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 40, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. TYPING INDICATOR ---
class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({super.key});
  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
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
        duration: const Duration(milliseconds: 400),
      ),
    );
    for (int i = 0; i < 3; i++) {
      _animations.add(
        Tween<double>(begin: 0, end: -6).animate(
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
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12, bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF9983F3), Color(0xFFFF4B72)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4B72).withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 14,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
                bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF9983F3),
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

// --- 5. ANIMATED MESSAGE WRAPPER ---
class AiAnimatedMessage extends StatefulWidget {
  final Widget child;
  const AiAnimatedMessage({super.key, required this.child});
  @override
  State<AiAnimatedMessage> createState() => _AiAnimatedMessageState();
}

class _AiAnimatedMessageState extends State<AiAnimatedMessage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
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
