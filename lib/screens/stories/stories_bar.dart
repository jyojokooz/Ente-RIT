// ===============================
// FILE PATH: lib/screens/stories/stories_bar.dart
// ===============================

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

  // Instagram-style gradient matching the provided image
  final LinearGradient _activeStoryGradient = const LinearGradient(
    colors: [
      Color(0xFFD300C5), // Deep Purple (Bottom Left)
      Color(0xFFFF0069), // Pink (Mid)
      Color(0xFFFF7A00), // Orange (Top Right)
      Color(0xFFFFD600), // Yellow (Bottom Right Edge)
    ],
    stops: [0.0, 0.4, 0.8, 1.0],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

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
      margin: const EdgeInsets.only(top: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
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
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    // Using 28 radius on a 78 box gives the exact squircle shape from the image
                    borderRadius: BorderRadius.circular(28),
                    gradient: hasStory ? _activeStoryGradient : null,
                    border:
                        hasStory
                            ? null
                            : Border.all(
                              color:
                                  isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                              width: 1.5,
                            ),
                  ),
                  padding: const EdgeInsets.all(
                    2.5,
                  ), // Gradient border thickness
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: bgColor,
                    ),
                    padding: const EdgeInsets.all(
                      3.0,
                    ), // Inner gap before image
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
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
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF4A3AFF,
                      ), // Deep Purple/Blue matching the image
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: bgColor,
                        width:
                            3.5, // Thick white/black stroke to cut into the avatar
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Your Story",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.grey.shade800,
              letterSpacing: 0.2,
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: allSeen ? null : _activeStoryGradient,
                border:
                    allSeen
                        ? Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          width: 1.5,
                        )
                        : null,
              ),
              padding: const EdgeInsets.all(2.5), // Gradient border thickness
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: bgColor,
                ),
                padding: const EdgeInsets.all(3.0), // Inner gap before image
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 78, // Constraint to match container width
              child: Text(
                story.userName.split(' ')[0], // First name only
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      allSeen
                          ? (isDark ? Colors.white54 : Colors.grey.shade600)
                          : (isDark ? Colors.white : Colors.black87),
                  fontWeight: allSeen ? FontWeight.w500 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
