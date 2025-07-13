import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> stories = [
    {'name': 'You', 'image': 'https://i.pravatar.cc/150?img=11', 'isYou': true},
    {'name': 'Benjamin', 'image': 'https://i.pravatar.cc/150?img=32'},
    {'name': 'Farita', 'image': 'https://i.pravatar.cc/150?img=49'},
    {'name': 'Marie', 'image': 'https://i.pravatar.cc/150?img=31'},
    {'name': 'Jason', 'image': 'https://i.pravatar.cc/150?img=60'},
    {'name': 'Clara', 'image': 'https://i.pravatar.cc/150?img=21'},
  ];

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
        onPressed: () {},
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
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            _buildTopBar(primaryTextColor, cardBackgroundColor),
            const SizedBox(height: 16),
            _buildStoriesSection(secondaryTextColor, cardBackgroundColor),
            const SizedBox(height: 16),
            _buildPostCard(
              name: 'Claire Dangais',
              username: '@ClaireD15',
              userImage: 'https://i.pravatar.cc/150?img=26',
              postImage:
                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1470',
              likes: 122,
              comments: 10,
              cardColor: cardBackgroundColor,
              textColor: primaryTextColor,
              secondaryColor: secondaryTextColor,
              accentColor: primaryAccentColor,
            ),
            _buildPostCard(
              name: 'Farita Smith',
              username: '@SmithFa',
              userImage: 'https://i.pravatar.cc/150?img=49',
              postImage:
                  'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1470',
              likes: 451,
              comments: 53,
              cardColor: cardBackgroundColor,
              textColor: primaryTextColor,
              secondaryColor: secondaryTextColor,
              accentColor: primaryAccentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color textColor, Color iconBgColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          // --- FIX APPLIED HERE ---
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
    required String name,
    required String username,
    required String userImage,
    required String postImage,
    required int likes,
    required int comments,
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
    required Color accentColor,
  }) {
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
                  backgroundImage: NetworkImage(userImage),
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
                    Text(
                      username,
                      style: GoogleFonts.poppins(color: secondaryColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.network(
                postImage,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
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
