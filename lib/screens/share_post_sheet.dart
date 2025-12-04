// ===============================
// FILE NAME: share_post_sheet.dart
// FILE PATH: lib/screens/share_post_sheet.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class SharePostSheet extends StatefulWidget {
  final String postId;
  const SharePostSheet({super.key, required this.postId});

  @override
  State<SharePostSheet> createState() => _SharePostSheetState();
}

class _SharePostSheetState extends State<SharePostSheet> {
  final _currentUser = FirebaseAuth.instance.currentUser!;
  String _searchQuery = "";
  final Set<String> _sentUsers = {}; // Track who we sent to locally

  Future<void> _sendPostToUser(
    String receiverId,
    String receiverName,
    String receiverImage,
  ) async {
    setState(() {
      _sentUsers.add(
        receiverId,
      ); // Optimistic UI update (show "Sent" immediately)
    });

    try {
      // 1. Determine Chat Room ID
      List<String> ids = [_currentUser.uid, receiverId];
      ids.sort();
      String chatRoomId = ids.join('_');

      // 2. Setup Chat References
      final chatDocRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatRoomId);
      final messagesCollection = chatDocRef.collection('messages');
      final batch = FirebaseFirestore.instance.batch();
      final timestamp = FieldValue.serverTimestamp();

      // 3. Create/Update Chat Room Metadata
      batch.set(chatDocRef, {
        'participants': [_currentUser.uid, receiverId],
        'participantNames': {
          _currentUser.uid: _currentUser.displayName ?? 'Me',
          receiverId: receiverName,
        },
        'participantImages': {
          _currentUser.uid: _currentUser.photoURL ?? '',
          receiverId: receiverImage,
        },
        'lastMessage': 'Sent a post',
        'lastMessageTimestamp': timestamp,
        'unreadCounts.${receiverId}': FieldValue.increment(1),
      }, SetOptions(merge: true));

      // 4. Create the "Post" Message
      final newMessageRef = messagesCollection.doc();
      batch.set(newMessageRef, {
        'senderId': _currentUser.uid,
        'text': '',
        'timestamp': timestamp,
        'type': 'post',
        'postId': widget.postId,
      });

      await batch.commit();
    } catch (e) {
      if (mounted) {
        setState(() {
          _sentUsers.remove(receiverId); // Revert if failed
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to send")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Share",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Explicit Black
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.black), // Black Text Input
              decoration: InputDecoration(
                hintText: "Search",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged:
                  (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          const Divider(height: 1),

          // User List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Limit fetch size to improve performance
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .limit(50)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _ShareSheetSkeleton(); // Smooth loading state
                }

                if (!snapshot.hasData)
                  return const Center(child: Text("No users found"));

                // Filter users locally
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

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final name = userData['displayName'] ?? 'User';
                    final username = userData['username'] ?? '';
                    final image = userData['profilePhotoUrl'] ?? '';
                    final bool isSent = _sentUsers.contains(userId);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage:
                            image.isNotEmpty
                                ? CachedNetworkImageProvider(image)
                                : null,
                        child:
                            image.isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // Explicit Black
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '@$username',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600], // Explicit Grey
                          fontSize: 12,
                        ),
                      ),
                      trailing: SizedBox(
                        height: 32,
                        child: ElevatedButton(
                          onPressed:
                              isSent
                                  ? null
                                  : () => _sendPostToUser(userId, name, image),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSent ? Colors.white : Colors.black,
                            foregroundColor:
                                isSent ? Colors.black : Colors.white,
                            disabledBackgroundColor: Colors.white,
                            disabledForegroundColor: Colors.grey,
                            side:
                                isSent
                                    ? BorderSide(color: Colors.grey.shade300)
                                    : null,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: Text(
                            isSent ? "Sent" : "Send",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- SKELETON LOADER TO PREVENT JANK ---
class _ShareSheetSkeleton extends StatelessWidget {
  const _ShareSheetSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                const CircleAvatar(radius: 24, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 12, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 60, height: 10, color: Colors.white),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
