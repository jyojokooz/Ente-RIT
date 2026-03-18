// ===============================
// FILE NAME: share_post_sheet.dart
// FILE PATH: lib/screens/share_post_sheet.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SharePostSheet extends StatefulWidget {
  final String postId;
  const SharePostSheet({super.key, required this.postId});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  final Set<String> _selectedUserIds = {};
  bool _isSending = false;

  late Future<List<DocumentSnapshot>> _friendsFuture;
  Map<String, dynamic> _shareCounts = {};

  @override
  void initState() {
    super.initState();
    _friendsFuture = _fetchFriendsAndSort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches ONLY the user's connections and sorts them by how many times they've shared with them
  Future<List<DocumentSnapshot>> _fetchFriendsAndSort() async {
    try {
      // 1. Get current user's connections and share counts
      final meDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      final data = meDoc.data() as Map<String, dynamic>? ?? {};

      final List<dynamic> connections = data['connections'] ?? [];
      _shareCounts = data['shareCounts'] ?? {};

      if (connections.isEmpty) return [];

      // 2. Fetch the user documents for these connections
      // Firestore 'whereIn' only supports up to 10 items, so we chunk the requests
      List<DocumentSnapshot> friendDocs = [];
      for (var i = 0; i < connections.length; i += 10) {
        int end = (i + 10 < connections.length) ? i + 10 : connections.length;
        final chunk = connections.sublist(i, end);

        final snap =
            await FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

        friendDocs.addAll(snap.docs);
      }

      // 3. Sort by share count (highest first)
      friendDocs.sort((a, b) {
        final countA = (_shareCounts[a.id] as num?)?.toInt() ?? 0;
        final countB = (_shareCounts[b.id] as num?)?.toInt() ?? 0;
        return countB.compareTo(countA); // Descending order
      });

      return friendDocs;
    } catch (e) {
      debugPrint("Error fetching friends for sharing: $e");
      return [];
    }
  }

  void _toggleSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _sendToSelectedUsers(List<DocumentSnapshot> allFriends) async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (var userId in _selectedUserIds) {
        // Find user data
        final userDoc = allFriends.firstWhere((doc) => doc.id == userId);
        final userData = userDoc.data() as Map<String, dynamic>;

        final receiverName = userData['displayName'] ?? 'User';
        final receiverImage = userData['profilePhotoUrl'] ?? '';

        // 1. Determine Chat Room ID
        List<String> ids = [_currentUser.uid, userId];
        ids.sort();
        String chatRoomId = ids.join('_');

        // 2. Chat References
        final chatDocRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatRoomId);
        final newMessageRef = chatDocRef.collection('messages').doc();

        // 3. Update Chat Metadata
        batch.set(chatDocRef, {
          'participants': [_currentUser.uid, userId],
          'participantNames': {
            _currentUser.uid: _currentUser.displayName ?? 'Me',
            userId: receiverName,
          },
          'participantImages': {
            _currentUser.uid: _currentUser.photoURL ?? '',
            userId: receiverImage,
          },
          'lastMessage': 'Sent a post',
          'lastMessageTimestamp': timestamp,
          'unreadCounts.$userId': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // 4. Create Message
        batch.set(newMessageRef, {
          'senderId': _currentUser.uid,
          'text': '',
          'timestamp': timestamp,
          'type': 'post',
          'postId': widget.postId,
        });

        // 5. Update Share Count for the current user
        batch.set(
          FirebaseFirestore.instance.collection('users').doc(_currentUser.uid),
          {
            'shareCounts': {userId: FieldValue.increment(1)},
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sent to ${_selectedUserIds.length} friend${_selectedUserIds.length > 1 ? 's' : ''}",
            ),
            backgroundColor: const Color(0xFFFF3E8E), // Pink branding
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error sending: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : Colors.white;
    final cardColor = isDark ? const Color(0xFF252528) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        snap: true,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // --- Drag Handle ---
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Title ---
                Text(
                  "Share with Friends",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                // --- Search Bar ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: subtitleColor,
                          size: 20,
                        ),
                        hintText: "Search friends...",
                        hintStyle: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged:
                          (val) =>
                              setState(() => _searchQuery = val.toLowerCase()),
                    ),
                  ),
                ),

                // --- Friend Grid ---
                Expanded(
                  child: FutureBuilder<List<DocumentSnapshot>>(
                    future: _friendsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF3E8E),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_alt_outlined,
                                size: 50,
                                color:
                                    isDark
                                        ? Colors.white24
                                        : Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No friends to share with.",
                                style: GoogleFonts.poppins(
                                  color: subtitleColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "Mingle with people first!",
                                style: GoogleFonts.poppins(
                                  color: subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final allFriends = snapshot.data!;

                      // Local search filter
                      final filteredFriends =
                          allFriends.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name =
                                (data['displayName'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final username =
                                (data['username'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            return name.contains(_searchQuery) ||
                                username.contains(_searchQuery);
                          }).toList();

                      if (filteredFriends.isEmpty) {
                        return Center(
                          child: Text(
                            "No friends match your search.",
                            style: GoogleFonts.poppins(color: subtitleColor),
                          ),
                        );
                      }

                      return GridView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 0.7, // Taller to fit names
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredFriends.length,
                        itemBuilder: (context, index) {
                          final userDoc = filteredFriends[index];
                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          final userId = userDoc.id;
                          final name = userData['displayName'] ?? 'User';
                          final image = userData['profilePhotoUrl'] ?? '';
                          final isSelected = _selectedUserIds.contains(userId);

                          // Check if they are a top friend (e.g. they have a share count > 0 and are in the first row)
                          final shareCount =
                              (_shareCounts[userId] as num?)?.toInt() ?? 0;
                          final isTopFriend =
                              index < 4 &&
                              shareCount > 0 &&
                              _searchQuery.isEmpty;

                          return GestureDetector(
                            onTap: () => _toggleSelection(userId),
                            child: Column(
                              children: [
                                // Avatar Stack
                                Expanded(
                                  child: Stack(
                                    children: [
                                      // Squarcle Avatar
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          color: cardColor,
                                          image:
                                              image.isNotEmpty
                                                  ? DecorationImage(
                                                    image:
                                                        CachedNetworkImageProvider(
                                                          image,
                                                        ),
                                                    fit: BoxFit.cover,
                                                  )
                                                  : null,
                                        ),
                                        child:
                                            image.isEmpty
                                                ? Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: subtitleColor,
                                                  ),
                                                )
                                                : null,
                                      ),

                                      // Selection Overlay
                                      if (isSelected)
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            color: Colors.black.withOpacity(
                                              0.4,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFF00C6FB,
                                              ), // Cyan selection border
                                              width: 3,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF00C6FB),
                                              size: 30,
                                            ),
                                          ),
                                        ),

                                      // "Top Friend" Badge
                                      if (isTopFriend && !isSelected)
                                        Positioned(
                                          bottom: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.amber,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.star_rounded,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Name
                                Text(
                                  name
                                      .split(' ')
                                      .first, // Show first name only for cleanliness
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? const Color(0xFF00C6FB)
                                            : textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // --- Send Button (Bottom Fixed) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient:
                          _selectedUserIds.isNotEmpty && !_isSending
                              ? const LinearGradient(
                                colors: [Color(0xFF00C6FB), Color(0xFF005BEA)],
                              ) // Blue Gradient
                              : null,
                      color: _selectedUserIds.isEmpty ? cardColor : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ElevatedButton(
                      onPressed:
                          (_selectedUserIds.isEmpty || _isSending)
                              ? null
                              : () async {
                                final snapshotList = await _friendsFuture;
                                _sendToSelectedUsers(snapshotList);
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child:
                          _isSending
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                "Send${_selectedUserIds.isNotEmpty ? ' (${_selectedUserIds.length})' : ''}",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _selectedUserIds.isEmpty
                                          ? subtitleColor
                                          : Colors.white,
                                ),
                              ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
