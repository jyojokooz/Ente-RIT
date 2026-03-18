// ===============================
// FILE NAME: requests_screen.dart
// FILE PATH: lib/screens/requests_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'pages/profile_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser!;

  // We keep track of ghosts here as well to immediately remove them from UI
  final Set<String> _ghostUsers = {};

  Future<void> _acceptRequest(String requestFromId) async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final otherUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(requestFromId);

    final batch = FirebaseFirestore.instance.batch();

    batch.update(currentUserRef, {
      'connections': FieldValue.arrayUnion([requestFromId]),
      'receivedRequests': FieldValue.arrayRemove([requestFromId]),
    });
    batch.update(otherUserRef, {
      'connections': FieldValue.arrayUnion([_currentUser.uid]),
      'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();

    final currentUserDoc = await currentUserRef.get();
    final currentUserData = currentUserDoc.data() ?? {};

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': requestFromId,
      'title': 'Connection Accepted',
      'body':
          '${currentUserData['displayName'] ?? 'Someone'} accepted your connection request.',
      'type': 'connection_accepted',
      'relatedDocId': _currentUser.uid,
      'triggeringUserId': _currentUser.uid,
      'triggeringUserName': currentUserData['displayName'] ?? 'Someone',
      'triggeringUserAvatarUrl': currentUserData['profilePhotoUrl'] ?? '',
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _declineRequest(String requestFromId) async {
    final currentUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid);
    final otherUserRef = FirebaseFirestore.instance
        .collection('users')
        .doc(requestFromId);

    final batch = FirebaseFirestore.instance.batch();
    batch.update(currentUserRef, {
      'receivedRequests': FieldValue.arrayRemove([requestFromId]),
    });
    batch.update(otherUserRef, {
      'sentRequests': FieldValue.arrayRemove([_currentUser.uid]),
    });

    await batch.commit();
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
          'Connection Requests',
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
              child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
            );
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> rawRequests = userData['receivedRequests'] ?? [];

          // Filter out users we've identified as deleted
          final receivedRequests =
              rawRequests.where((id) => !_ghostUsers.contains(id)).toList();

          if (receivedRequests.isEmpty) {
            return _buildEmptyState(isDark, textColor);
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              final userId = receivedRequests[index];

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return _buildRequestTilePlaceholder(isDark);
                  }

                  if (!userSnapshot.data!.exists) {
                    // Mark as ghost so it doesn't show up again
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_ghostUsers.contains(userId)) {
                        setState(() {
                          _ghostUsers.add(userId);
                        });
                        // Automatically heal database
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(_currentUser.uid)
                            .update({
                              'receivedRequests': FieldValue.arrayRemove([
                                userId,
                              ]),
                            });
                      }
                    });
                    return const SizedBox.shrink();
                  }

                  final requestUserData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return _RequestTile(
                    userData: requestUserData,
                    onAccept: () => _acceptRequest(userId),
                    onDecline: () => _declineRequest(userId),
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
              Icons.person_add_disabled_outlined,
              size: 60,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No new requests',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your connection requests will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTilePlaceholder(bool isDark) {
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 100,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

// --- STYLIZED REQUEST TILE WIDGET ---
class _RequestTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onProfileTap;
  final bool isDark;

  const _RequestTile({
    required this.userData,
    required this.onAccept,
    required this.onDecline,
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFB165FF), Color(0xFFFF4B72)],
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
                      radius: 24,
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
                ),
              ),
              const SizedBox(width: 12),
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
                    ),
                    Text(
                      '@$username',
                      style: GoogleFonts.poppins(
                        color: mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onDecline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF161618) : Colors.grey.shade100,
                    foregroundColor: mutedTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Decline',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF3E8E), Color(0xFFFF9A44)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Accept',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
