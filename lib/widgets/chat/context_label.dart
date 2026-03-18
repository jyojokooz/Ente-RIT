// ===============================
// FILE PATH: lib/widgets/chat/context_label.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/ai_chat_message.dart'; // Import the model

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
