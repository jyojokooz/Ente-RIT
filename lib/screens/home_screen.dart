import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'classify_screen.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  List<DocumentSnapshot> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .orderBy('timestamp', descending: true)
              .get();
      if (mounted) {
        setState(() {
          _posts = querySnapshot.docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: ${e.toString()}')),
        );
      }
    }
  }

  void _onCommentTapped(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId)),
    ).then((_) {
      _fetchPosts();
    });
  }

  Future<void> _deletePost(String postId) async {
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
        _fetchPosts();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete post: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color screenBackgroundColor = Colors.black;
    const Color primaryAccentColor = Colors.yellow;
    const Color secondaryTextColor =
        Colors.white70; // <-- Define secondary color
    final Color cardBackgroundColor = Colors.grey.shade900;
    const Color buttonTextColor = Colors.black;

    return Scaffold(
      backgroundColor: screenBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          if (result == true) {
            _fetchPosts();
          }
        },
        backgroundColor: primaryAccentColor,
        elevation: 4.0,
        child: const Icon(Icons.add, color: buttonTextColor, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // --- FIX: PASS THE CORRECT COLORS ---
      bottomNavigationBar: _buildBottomAppBar(
        cardBackgroundColor,
        secondaryTextColor,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchPosts,
          backgroundColor: cardBackgroundColor,
          color: primaryAccentColor,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildTopBar(Colors.white, cardBackgroundColor),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              _isLoading
                  ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: primaryAccentColor,
                      ),
                    ),
                  )
                  : _posts.isEmpty
                  ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No posts yet. Be the first!',
                        style: GoogleFonts.poppins(color: secondaryTextColor),
                      ),
                    ),
                  )
                  : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final postSnapshot = _posts[index];
                      return PostCard(
                        postSnapshot: postSnapshot,
                        onCommentPressed:
                            () => _onCommentTapped(postSnapshot.id),
                        onDeletePressed: () => _deletePost(postSnapshot.id),
                      );
                    }, childCount: _posts.length),
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
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBgColor,
            ),
            child: Icon(Icons.camera_alt_outlined, color: textColor, size: 28),
          ),
          Text(
            'Explore',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBgColor,
            ),
            child: Icon(Icons.message_outlined, color: textColor, size: 28),
          ),
        ],
      ),
    );
  }

  // --- THIS METHOD IS NOW CORRECTED ---
  BottomAppBar _buildBottomAppBar(Color bgColor, Color iconColor) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      color: bgColor,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // 1. Home Icon is back
            IconButton(
              icon: Icon(Icons.home, color: iconColor),
              onPressed: () {
                // Since this IS the home screen, pressing it does nothing.
                // In a real app, you might scroll to the top.
              },
            ),
            // 2. New Classify Icon
            IconButton(
              icon: Icon(Icons.category_outlined, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClassifyScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 40), // Space for the FAB
            // 3. Profile Icon
            IconButton(
              icon: Icon(Icons.person_outline, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            // 4. Notifications Icon
            IconButton(
              icon: Icon(Icons.notifications_none, color: iconColor),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
