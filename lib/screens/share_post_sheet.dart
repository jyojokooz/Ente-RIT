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
  final Set<String> _selectedUserIds = {}; // Track selected users
  bool _isSending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _sendToSelectedUsers(List<DocumentSnapshot> allUsers) async {
    if (_selectedUserIds.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();

      for (var userId in _selectedUserIds) {
        // Find user data from the snapshot list to avoid extra fetches
        final userDoc = allUsers.firstWhere((doc) => doc.id == userId);
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

        // 3. Update Metadata
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
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sent to ${_selectedUserIds.length} people"),
            backgroundColor: const Color(0xFF4B00E0), // Blue/Purple
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
    // Fixed height to prevent keyboard jumps
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Header ---
          const SizedBox(height: 16),
          Text(
            "share",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),

          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.black),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "search",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged:
                    (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
          ),

          // --- User Grid ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .limit(50) // Limit for performance
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No users found"));
                }

                // Filter users locally based on search
                final users =
                    snapshot.data!.docs.where((doc) {
                      if (doc.id == _currentUser.uid) return false;
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['displayName'] ?? '').toString().toLowerCase();
                      final username =
                          (data['username'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          username.contains(_searchQuery);
                    }).toList();

                return Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  4, // 4 items per row like screenshot
                              childAspectRatio: 0.7, // Taller for name text
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final userDoc = users[index];
                          final userData =
                              userDoc.data() as Map<String, dynamic>;
                          final userId = userDoc.id;
                          final name = userData['displayName'] ?? 'User';
                          final image = userData['profilePhotoUrl'] ?? '';
                          final isSelected = _selectedUserIds.contains(userId);

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
                                          ), // Squarcle shape
                                          color: Colors.grey.shade200,
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
                                                ? const Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.grey,
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
                                              color: const Color(0xFF4B00E0),
                                              width: 3,
                                            ), // Blue Border
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Name
                                Text(
                                  name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // --- Send Button (Only shows at bottom) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Colors.black12)),
                      ),
                      child: ElevatedButton(
                        onPressed:
                            (_selectedUserIds.isEmpty || _isSending)
                                ? null
                                : () =>
                                    _sendToSelectedUsers(snapshot.data!.docs),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF3000F8,
                          ), // Bright Blue/Purple from screenshot
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
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
                                  ),
                                ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
