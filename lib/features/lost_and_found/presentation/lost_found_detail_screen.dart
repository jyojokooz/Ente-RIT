// ===============================
// FILE NAME: lost_found_detail_screen.dart
// FILE PATH: lib/screens/lost_found_detail_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/chat/presentation/chat_screen.dart';
import 'package:my_project/features/chat/presentation/chat_list_screen.dart';
import 'package:my_project/core/widgets/full_screen_image_viewer.dart';

class LostFoundDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot itemDoc;
  const LostFoundDetailScreen({super.key, required this.itemDoc});

  Future<void> _startOrNavigateToChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to contact the poster.'),
        ),
      );
      return;
    }

    final data = itemDoc.data() as Map<String, dynamic>;
    final posterId = data['userId'];
    final posterName = data['userName'] ?? 'User';

    String posterPhotoUrl = '';
    try {
      final posterDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(posterId)
              .get();
      if (posterDoc.exists) {
        posterPhotoUrl = posterDoc.data()?['profilePhotoUrl'] ?? '';
      }
    } catch (e) {}

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                receiverId: posterId,
                receiverName: posterName,
                receiverImageUrl: posterPhotoUrl,
              ),
        ),
      );
    }
  }

  Future<void> _markAsResolved(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('lost_and_found')
          .doc(itemDoc.id)
          .update({'isResolved': true});
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item marked as resolved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
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
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final data = itemDoc.data() as Map<String, dynamic>;
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyPost = currentUser != null && currentUser.uid == data['userId'];
    final isResolved = data['isResolved'] ?? false;
    final imageUrl = data['imageUrl'] as String?;
    final timestamp = data['createdAt'] as Timestamp?;
    final formattedDate =
        timestamp != null
            ? DateFormat.yMMMMd().add_jm().format(timestamp.toDate())
            : 'Date not available';

    final isLost = data['status'] == 'lost';
    final statusGradient =
        isLost
            ? const LinearGradient(
              colors: [Color(0xFFFF9A44), Color(0xFFFF3E8E)],
            )
            : const LinearGradient(
              colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
            );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350.0,
                pinned: true,
                backgroundColor: bgColor,
                iconTheme: IconThemeData(
                  color: isDark ? Colors.white : Colors.black,
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black45 : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      imageUrl != null && imageUrl.isNotEmpty
                          ? GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FullScreenImageViewer(
                                          imageUrl: imageUrl,
                                          heroTag: 'lf_${itemDoc.id}',
                                          postId:
                                              itemDoc
                                                  .id, // <-- ADDED THIS TO FIX THE ERROR
                                        ),
                                  ),
                                ),
                            child: Hero(
                              tag: 'lf_${itemDoc.id}',
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (c, u) => Container(
                                      color:
                                          isDark
                                              ? Colors.white10
                                              : Colors.black12,
                                    ),
                              ),
                            ),
                          )
                          : Container(
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: subtitleColor,
                            ),
                          ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0.0, -30.0, 0.0),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: statusGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isResolved
                                  ? "RESOLVED"
                                  : data['status'].toString().toUpperCase(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        data['title'] ?? 'No Title',
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildInfoContainer(
                        cardColor,
                        textColor,
                        subtitleColor,
                        Icons.location_on_rounded,
                        'Last Known Location',
                        data['location'] ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoContainer(
                        cardColor,
                        textColor,
                        subtitleColor,
                        Icons.person_rounded,
                        'Reported By',
                        data['userName'] ?? 'Anonymous',
                      ),
                      const SizedBox(height: 24),

                      Text(
                        "Description",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['description'] ?? 'No description provided.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: subtitleColor,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ).copyWith(bottom: 24),
              decoration: BoxDecoration(
                color: cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child:
                  isMyPost
                      ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => const ChatListScreen(),
                                    ),
                                  ),
                              icon: const Icon(Icons.forum_rounded),
                              label: const Text('Messages'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isDark
                                        ? const Color(0xFF161618)
                                        : Colors.grey.shade100,
                                foregroundColor: textColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          if (!isResolved) ...[
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF43E97B),
                                    Color(0xFF38F9D7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => _markAsResolved(context),
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Resolve',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                      : SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                isResolved
                                    ? null
                                    : () => _startOrNavigateToChat(context),
                            icon: const Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              isResolved ? 'Item Resolved' : 'Contact Poster',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledBackgroundColor: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: subtitleColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
