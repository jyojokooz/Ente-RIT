// ===============================
// FILE NAME: confession_screen.dart
// FILE PATH: lib/features/tools/confession_box/confession_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class ConfessionScreen extends StatefulWidget {
  const ConfessionScreen({super.key});

  @override
  State<ConfessionScreen> createState() => _ConfessionScreenState();
}

class _ConfessionScreenState extends State<ConfessionScreen> {
  final _confessionsRef = FirebaseFirestore.instance
      .collection('confessions')
      .orderBy('createdAt', descending: true);

  void _postConfession() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1C1C22) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE040FB), Color(0xFF7B61FF)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.masks_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anonymous Confession',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'Your identity will be hidden',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                maxLines: 5,
                maxLength: 500,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Write your confession...',
                  hintStyle: GoogleFonts.poppins(
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: GoogleFonts.poppins(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;
                    await FirebaseFirestore.instance
                        .collection('confessions')
                        .add({
                      'text': controller.text.trim(),
                      'likes': 0,
                      'likedBy': [],
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    'Post Anonymously',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE040FB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleLike(DocumentSnapshot doc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = doc.data() as Map<String, dynamic>;
    final likedBy = List<String>.from(data['likedBy'] ?? []);

    if (likedBy.contains(uid)) {
      likedBy.remove(uid);
    } else {
      likedBy.add(uid);
    }

    await doc.reference.update({
      'likedBy': likedBy,
      'likes': likedBy.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confession Box',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _confessionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE040FB)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.masks_rounded,
                    size: 64,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No confessions yet',
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to confess!',
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final text = data['text'] ?? '';
              final likes = data['likes'] ?? 0;
              final likedBy = List<String>.from(data['likedBy'] ?? []);
              final isLiked = uid != null && likedBy.contains(uid);
              final createdAt = data['createdAt'] as Timestamp?;
              final timeAgo = createdAt != null
                  ? timeago.format(createdAt.toDate())
                  : 'just now';

              // Alternate gradient colors for cards
              final gradients = [
                [
                  const Color(0xFFE040FB).withOpacity(0.05),
                  const Color(0xFF7B61FF).withOpacity(0.03),
                ],
                [
                  const Color(0xFF00B4D8).withOpacity(0.05),
                  const Color(0xFF43E97B).withOpacity(0.03),
                ],
                [
                  const Color(0xFFFF4B72).withOpacity(0.05),
                  const Color(0xFFFF9F1C).withOpacity(0.03),
                ],
              ];
              final gradientPair = gradients[index % gradients.length];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                  gradient: isDark
                      ? LinearGradient(
                          colors: gradientPair,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Anonymous header
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE040FB),
                                Color(0xFF7B61FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Anonymous',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            Text(
                              timeAgo,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Like Button
                    GestureDetector(
                      onTap: () => _toggleLike(doc),
                      child: Row(
                        children: [
                          Icon(
                            isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isLiked
                                ? const Color(0xFFFF4B72)
                                : subtitleColor,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$likes',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isLiked
                                  ? const Color(0xFFFF4B72)
                                  : subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _postConfession,
        backgroundColor: const Color(0xFFE040FB),
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: Text(
          'Confess',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
