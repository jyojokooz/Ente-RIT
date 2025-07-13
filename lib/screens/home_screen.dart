// lib/screens/home_screen.dart (NO CHANGES NEEDED, PROVIDED FOR CONTEXT)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'comments_screen.dart'; // Already correctly imported
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

  // ... stories list ...
  final List<Map<String, dynamic>> stories = [
    {'name': 'You', 'image': 'https://i.pravatar.cc/150?img=11', 'isYou': true},
    {'name': 'Benjamin', 'image': 'https://i.pravatar.cc/150?img=32'},
    {'name': 'Farita', 'image': 'https://i.pravatar.cc/150?img=49'},
    {'name': 'Marie', 'image': 'https://i.pravatar.cc/150?img=31'},
    {'name': 'Jason', 'image': 'https://i.pravatar.cc/150?img=60'},
    {'name': 'Clara', 'image': 'https://i.pravatar.cc/150?img=21'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    // ... no changes here
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
    // This is already correct. It navigates and then refreshes.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CommentsScreen(postId: postId)),
    ).then((_) {
      _fetchPosts();
    });
  }

  // ... build method and all other _build methods are unchanged ...
  @override
  Widget build(BuildContext context) {
    const Color screenBackgroundColor = Colors.black;
    const Color primaryAccentColor = Colors.yellow;
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
      bottomNavigationBar: _buildBottomAppBar(
        cardBackgroundColor,
        Colors.white70,
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
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _buildStoriesSection(
                  Colors.white70,
                  cardBackgroundColor,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                        style: GoogleFonts.poppins(color: Colors.white70),
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
            child: Icon(Icons.notifications_none, color: textColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection(Color textColor, Color avatarBgColor) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: avatarBgColor,
                      backgroundImage: NetworkImage(story['image']),
                    ),
                    if (story['isYou'] == true)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withAlpha(128),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  story['name'],
                  style: GoogleFonts.poppins(color: textColor, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

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
            IconButton(
              icon: Icon(Icons.home, color: iconColor),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline, color: iconColor),
              onPressed: () {},
            ),
            const SizedBox(width: 40),
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
