import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'stories_connector.dart';

class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});
  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  final StoriesService _service = StoriesService();
  final currentUser = FirebaseAuth.instance.currentUser;

  void _addStory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryCreatorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 115,
      margin: const EdgeInsets.only(top: 10),
      child: StreamBuilder<List<Story>>(
        stream: _service.getActiveStories(),
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];
          final Map<String, List<Story>> groupedStories = {};
          for (var story in stories) {
            if (!groupedStories.containsKey(story.userId)) {
              groupedStories[story.userId] = [];
            }
            groupedStories[story.userId]!.add(story);
          }
          final myStories = groupedStories[currentUser?.uid] ?? [];
          final otherUsersStories =
              groupedStories.values
                  .where((list) => list.first.userId != currentUser?.uid)
                  .toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 16),
            itemCount: 1 + otherUsersStories.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildMeButton(myStories);
              }
              final userStories = otherUsersStories[index - 1];
              return _buildStoryBubble(context, userStories);
            },
          );
        },
      ),
    );
  }

  Widget _buildMeButton(List<Story> myStories) {
    final bool hasStory = myStories.isNotEmpty;
    const gradient = LinearGradient(
      colors: [Color(0xFF833AB4), Color(0xFFFF2D55), Color(0xFFFFC107)],
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer Ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26), // SQUIRCLE SHAPE
                  gradient: hasStory ? gradient : null,
                  border:
                      hasStory
                          ? null
                          : Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
              // Inner Image Container
              GestureDetector(
                onTap: () {
                  if (hasStory) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoryViewScreen(stories: myStories),
                      ),
                    );
                  } else {
                    _addStory();
                  }
                },
                onLongPress: _addStory,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.5),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser?.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          ImageProvider? imageProvider;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final photoUrl = data['profilePhotoUrl'];
                            if (photoUrl != null && photoUrl.isNotEmpty) {
                              imageProvider = CachedNetworkImageProvider(
                                photoUrl,
                              );
                            }
                          }
                          imageProvider ??= const AssetImage(
                            'assets/default_avatar.png',
                          );
                          return Image(image: imageProvider, fit: BoxFit.cover);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // Plus Badge
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: _addStory,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF4A34F6,
                      ), // Purple/Blue color from image
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Your Story",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryBubble(BuildContext context, List<Story> stories) {
    final story = stories.last;
    final myUid = currentUser?.uid;
    final bool allSeen = stories.every((s) => s.viewers.contains(myUid));

    ImageProvider imageProvider;
    if (story.userImage.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(story.userImage);
    } else {
      imageProvider = const AssetImage('assets/default_avatar.png');
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryViewScreen(stories: stories)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            // Outer Ring
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26), // SQUIRCLE SHAPE
                gradient:
                    allSeen
                        ? null
                        : const LinearGradient(
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFFF2D55),
                            Color(0xFFFFC107),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                color: allSeen ? Colors.grey.shade300 : null,
              ),
              child: Container(
                margin: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Image(image: imageProvider, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.userName.split(' ')[0],
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: allSeen ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
