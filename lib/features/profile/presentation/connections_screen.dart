import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project/features/profile/presentation/profile_screen.dart';

class ConnectionsScreen extends StatefulWidget {
  final String title;
  final List<dynamic> userIds;
  final String ownerId; // <-- ADDED: To know whose profile we are cleaning up

  const ConnectionsScreen({
    super.key,
    required this.title,
    required this.userIds,
    required this.ownerId, // <-- ADDED
  });

  @override
  State<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  final Set<String> _ghostUsers =
      {}; // Tracks deleted users to hide them instantly

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    // Filter out ghost users locally so the UI updates instantly
    final activeUsers =
        widget.userIds.where((id) => !_ghostUsers.contains(id)).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          activeUsers.isEmpty
              ? _buildEmptyState(isDark, textColor)
              : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: activeUsers.length,
                itemBuilder: (context, index) {
                  final userId = activeUsers[index];

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildShimmerTile(isDark);
                      }

                      // --- THE FIX: SELF-HEALING DATABASE LOGIC ---
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && !_ghostUsers.contains(userId)) {
                            setState(() => _ghostUsers.add(userId));
                            // Automatically remove the deleted user from the owner's connections
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.ownerId)
                                .update({
                                  'connections': FieldValue.arrayRemove([
                                    userId,
                                  ]),
                                })
                                .catchError((_) {});
                          }
                        });
                        return const SizedBox.shrink(); // Hide the ghost user
                      }

                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;

                      return _MingleTile(
                        userId: userId,
                        userData: userData,
                        isDark: isDark,
                      );
                    },
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              size: 60,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No mingles yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with peers to see them here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerTile(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _MingleTile extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final bool isDark;

  const _MingleTile({
    required this.userId,
    required this.userData,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    final userImage = userData['profilePhotoUrl'] as String?;
    final displayName = userData['displayName'] ?? 'Unknown User';
    final username = userData['username'] ?? 'unknown';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: userId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor:
                      isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  backgroundImage:
                      (userImage != null && userImage.isNotEmpty)
                          ? CachedNetworkImageProvider(userImage)
                          : null,
                  child:
                      (userImage == null || userImage.isEmpty)
                          ? Icon(Icons.person, color: mutedTextColor)
                          : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '@$username',
                    style: GoogleFonts.poppins(
                      color: mutedTextColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: mutedTextColor, size: 24),
          ],
        ),
      ),
    );
  }
}
