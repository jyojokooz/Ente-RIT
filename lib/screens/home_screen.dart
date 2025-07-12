import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_screen.dart'; // This relative import works because both files are in lib/screens/

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Get the current user from Firebase Auth
  final user = FirebaseAuth.instance.currentUser;

  // Mock data for the stories
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
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFF3D8E4),
        elevation: 4.0,
        child: const Icon(Icons.add, color: Color(0xFF6B55C9), size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildStoriesSection(),
            const SizedBox(height: 16),
            _buildPostCard(
              name: 'Claire Dangais',
              username: '@ClaireD15',
              userImage: 'https://i.pravatar.cc/150?img=26',
              postImage:
                  'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1470',
              likes: 122,
              comments: 10,
            ),
            _buildPostCard(
              name: 'Farita Smith',
              username: '@SmithFa',
              userImage: 'https://i.pravatar.cc/150?img=49',
              postImage:
                  'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1470',
              likes: 451,
              comments: 53,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.black87,
              size: 28,
            ),
          ),
          const Text(
            'Explore',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'sans-serif',
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.black87,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
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
                      backgroundColor: Colors.grey[300],
                      backgroundImage: NetworkImage(story['image']),
                    ),
                    if (story['isYou'] == true)
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(153),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black54,
                          size: 30,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(story['name']),
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5FD),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(username, style: const TextStyle(color: Colors.grey)),
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
                    const Icon(Icons.chat_bubble_outline, size: 22),
                    const SizedBox(width: 5),
                    Text(comments.toString()),
                    const SizedBox(width: 20),
                    const Icon(Icons.favorite, color: Colors.red, size: 22),
                    const SizedBox(width: 5),
                    Text(likes.toString()),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.send_outlined, size: 22),
                    SizedBox(width: 20),
                    Icon(Icons.bookmark_border_outlined, size: 22),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // In lib/screens/home_screen.dart

  // ... (keep the rest of the file the same)

  // UPDATED BottomAppBar
  BottomAppBar _buildBottomAppBar() {
    const Color iconColor = Color(0xFF7B6BC4);
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 10.0,
      color: const Color(0xFFE4E1FF),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home, color: iconColor),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: iconColor),
              onPressed: () {},
            ),
            const SizedBox(width: 40), // The space for the FAB
            // THIS IS THE CORRECTED PROFILE BUTTON NAVIGATION
            IconButton(
              icon: const Icon(Icons.person_outline, color: iconColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // FIX: ProfileScreen no longer takes userEmail
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: iconColor),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
