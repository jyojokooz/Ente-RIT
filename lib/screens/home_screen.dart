import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/reusable_bottom_app_bar.dart'; // Reusable widget handles navigation
import 'comments_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'chat_list_screen.dart';
import 'post_card.dart';
// import 'classify_screen.dart'; // <-- FIX #1: REMOVED UNUSED IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  DateTime? _lastPressedAt;

  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    final isLiked = currentLikes.contains(user.uid);
    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  void _onCommentTapped(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId)),
    );
  }

  void _onProfileTapped(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }

  Future<void> _deletePost(String postId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final bool? didRequestDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text('Delete Post?'),
          content: const Text(
            'Are you sure you want to permanently delete this post?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (didRequestDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (scaffoldMessenger.mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryAccentColor = Colors.yellow;
    final Color cardBackgroundColor = Colors.grey.shade900;
    const Color buttonTextColor = Colors.black;

    // --- FIX #2: USING POPSCOPE WITH THE LATEST CALLBACK ---
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;

        final now = DateTime.now();
        final isFirstPress =
            _lastPressedAt == null ||
            now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (isFirstPress) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        floatingActionButton: FloatingActionButton(
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              ),
          backgroundColor: primaryAccentColor,
          elevation: 4.0,
          child: const Icon(Icons.add, color: buttonTextColor, size: 30),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: const ReusableBottomAppBar(
          activeScreen: ActiveScreen.home,
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopBar(Colors.white, cardBackgroundColor),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: primaryAccentColor,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Something went wrong!',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No posts yet. Be the first!',
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                      ),
                    );
                  }

                  final posts = snapshot.data!.docs;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final postSnapshot = posts[index];
                      final postData =
                          postSnapshot.data() as Map<String, dynamic>;
                      final postAuthorId = postData['userId'] ?? '';
                      final currentLikes = postData['likes'] ?? [];

                      return PostCard(
                        postSnapshot: postSnapshot,
                        onCommentPressed:
                            () => _onCommentTapped(postSnapshot.id),
                        onDeletePressed: () => _deletePost(postSnapshot.id),
                        onProfileTapped: () => _onProfileTapped(postAuthorId),
                        onLikePressed:
                            () => _toggleLike(postSnapshot.id, currentLikes),
                      );
                    }, childCount: posts.length),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color textColor, Color iconBgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(Icons.search, color: textColor, size: 28),
            ),
          ),
          Text(
            'Explore',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          GestureDetector(
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatListScreen(),
                  ),
                ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBgColor,
              ),
              child: Icon(Icons.message_outlined, color: textColor, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
