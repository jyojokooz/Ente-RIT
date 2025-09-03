import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatMessagePlaceholder extends StatelessWidget {
  final bool isMe;

  const ChatMessagePlaceholder({super.key, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe)
              const CircleAvatar(radius: 16, backgroundColor: Colors.white),
            const SizedBox(width: 8),
            Container(
              height: 40,
              width: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
