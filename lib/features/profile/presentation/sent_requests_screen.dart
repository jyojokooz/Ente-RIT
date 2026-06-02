// ===============================
// FILE NAME: sent_requests_screen.dart
// FILE PATH: lib/screens/sent_requests_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/profile/presentation/profile_screen.dart';

class SentRequestsScreen extends StatefulWidget {
  const SentRequestsScreen({super.key});

  @override
  State<SentRequestsScreen> createState() => _SentRequestsScreenState();
}

class _SentRequestsScreenState extends State<SentRequestsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final Set<String> _ghostUsers = {};

  Future<void> _cancelSentRequest(String targetUserId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final meRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid);
      final themRef = FirebaseFirestore.instance
          .collection('users')
          .doc(targetUserId);

      batch.update(meRef, {
        'sentRequests': FieldValue.arrayRemove([targetUserId]),
      });
      batch.update(themRef, {
        'receivedRequests': FieldValue.arrayRemove([_currentUser.uid]),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request cancelled."),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to cancel request: $e"),
            backgroundColor: Colors.redAccent,
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
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Sent Requests',
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
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(_currentUser.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9A44)),
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> rawRequests = userData['sentRequests'] ?? [];

          // Filter out users we've identified as deleted
          final sentRequests =
              rawRequests.where((id) => !_ghostUsers.contains(id)).toList();

          if (sentRequests.isEmpty) {
            return _buildEmptyState(isDark, textColor);
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: sentRequests.length,
            itemBuilder: (context, index) {
              final userId = sentRequests[index];

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return _buildPlaceholder(isDark);
                  }

                  if (!userSnapshot.data!.exists) {
                    // Mark as ghost and heal database
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_ghostUsers.contains(userId)) {
                        setState(() => _ghostUsers.add(userId));
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_currentUser.uid)
                            .update({
                              'sentRequests': FieldValue.arrayRemove([userId]),
                            });
                      }
                    });
                    return const SizedBox.shrink();
                  }

                  final requestUserData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return _SentRequestTile(
                    userData: requestUserData,
                    onCancelRequest: () => _cancelSentRequest(userId),
                    onProfileTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(userId: userId),
                          ),
                        ),
                    isDark: isDark,
                  );
                },
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
              Icons.send_outlined,
              size: 60,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No sent requests',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you ask to mingle, they will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 90,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// --- TILE UI ---
class _SentRequestTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onCancelRequest;
  final VoidCallback onProfileTap;
  final bool isDark;

  const _SentRequestTile({
    required this.userData,
    required this.onCancelRequest,
    required this.onProfileTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.white54 : Colors.grey.shade600;

    final userImage = userData['profilePhotoUrl'] ?? '';
    final displayName = userData['displayName'] ?? 'A User';
    final username = userData['username'] ?? '';

    return Container(
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
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 26,
              backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              backgroundImage:
                  userImage.isNotEmpty
                      ? CachedNetworkImageProvider(userImage)
                      : null,
              child:
                  userImage.isEmpty
                      ? Icon(Icons.person, color: mutedTextColor)
                      : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@$username',
                  style: GoogleFonts.poppins(
                    color: mutedTextColor,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCancelRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF161618) : Colors.grey.shade100,
              foregroundColor: mutedTextColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
