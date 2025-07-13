import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> _posts = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    const Color screenBackgroundColor = Colors.black;
    const Color primaryAccentColor = Colors.yellow;
    const Color primaryTextColor = Colors.white;
    const Color secondaryTextColor = Colors.white70;
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
                child: _buildTopBar(primaryTextColor, cardBackgroundColor),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: _buildStoriesSection(
                  secondaryTextColor,
                  cardBackgroundColor,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _isLoading
                  ? SliverFillRemaining(
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
                      final post = _posts[index].data() as Map<String, dynamic>;
                      return _buildPostCard(
                        postData: post,
                        cardColor: cardBackgroundColor,
                        textColor: primaryTextColor,
                        secondaryColor: secondaryTextColor,
                        accentColor: primaryAccentColor,
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

  Widget _buildPostCard({
    required Map<String, dynamic> postData,
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
    final String name = postData['userName'] ?? 'Unknown User';
    final String userImage =
        postData['userImageUrl'] ?? 'https://i.pravatar.cc/150';
    final String postImage = postData['postImageUrl'] ?? '';
    final String caption = postData['caption'] ?? '';
    final int likes = postData['likes'] ?? 0;
    final int comments = postData['comments'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  caption,
                  // --- FIX APPLIED HERE ---
                  style: GoogleFonts.poppins(
                    color: textColor.withAlpha((255 * 0.9).toInt()),
                  ),
                ),
              ),
            if (postImage.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(
                  postImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 300,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 300,
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.yellow),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 22,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      comments.toString(),
                      style: TextStyle(color: secondaryColor),
                    ),
                    const SizedBox(width: 20),
                    Icon(Icons.favorite, color: accentColor, size: 22),
                    const SizedBox(width: 5),
                    Text(
                      likes.toString(),
                      style: TextStyle(color: secondaryColor),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.send_outlined, size: 22, color: secondaryColor),
                    const SizedBox(width: 20),
                    Icon(
                      Icons.bookmark_border_outlined,
                      size: 22,
                      color: secondaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
