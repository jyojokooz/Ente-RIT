// ===============================
// FILE PATH: lib/features/stories/presentation/stories_bar.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:my_project/features/stories/presentation/stories_connector.dart';
import 'package:my_project/features/stories/providers/stories_provider.dart';

// 1. Changed to ConsumerStatefulWidget
class StoriesBar extends ConsumerStatefulWidget {
  const StoriesBar({super.key});

  @override
  ConsumerState<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends ConsumerState<StoriesBar> {
  final currentUser = FirebaseAuth.instance.currentUser;

  // Vibrant Pink/Purple/Blue gradient matching your design image
  final LinearGradient _activeStoryGradient = const LinearGradient(
    colors: [
      Color(0xFF5A32FA), // Purple
      Color(0xFFD300C5), // Magenta/Pink
      Color(0xFFFF0069), // Hot Pink
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  void _addStory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StoryCreatorScreen()),
    );
  }

  // Helper to extract department acronym like the post card
  String _getAcronym(String name) {
    if (name.isEmpty) return "";
    String lowerName = name.toLowerCase();

    if (lowerName.contains("mca") || lowerName.contains("application")) {
      return "MCA";
    }
    if (lowerName.contains("computer")) return "CSE";
    if (lowerName.contains("mechanical")) return "ME";
    if (lowerName.contains("electrical") && lowerName.contains("electronics")) {
      return "EEE";
    }
    if (lowerName.contains("electronics") &&
        lowerName.contains("communication")) {
      return "ECE";
    }
    if (lowerName.contains("civil")) return "CE";
    if (lowerName.contains("architecture")) return "B.Arch";

    List<String> words = name.split(" ");
    if (words.length > 1) {
      return words.take(2).map((e) => e[0].toUpperCase()).join();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Watch the Riverpod provider instead of using StreamBuilder
    final storiesAsync = ref.watch(activeStoriesProvider);

    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: storiesAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF5A32FA)),
            ),
        error: (error, stack) => const SizedBox.shrink(),
        data: (stories) {
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
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
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
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: ClipOval(
                      // Still safe to use a standard stream here since it's just one document fetch,
                      // but can be upgraded to Riverpod later.
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
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _addStory,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF833AB4), // Vibrant purple
                      shape: BoxShape.circle,
                      border: Border.all(color: bgColor, width: 3.0),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Your Story",
            style: GoogleFonts.poppins(
              fontSize: 11,
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
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: allSeen ? null : _activeStoryGradient,
                border:
                    allSeen
                        ? Border.all(
                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                          width: 1.5,
                        )
                        : null,
              ),
              padding: const EdgeInsets.all(2.5),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                ),
                padding: const EdgeInsets.all(2.5),
                child: ClipOval(
                  child: Image(image: imageProvider, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 6),
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(story.userId)
                      .snapshots(),
              builder: (context, userSnap) {
                String labelText = story.userName.split(' ')[0];

                if (userSnap.hasData && userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>;
                  final department = data['department'] ?? '';
                  if (department.isNotEmpty) {
                    labelText = _getAcronym(department);
                  }
                }

                return SizedBox(
                  width: 74,
                  child: Text(
                    labelText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
