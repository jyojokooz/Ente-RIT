// ===============================
// FILE NAME: story_view_screen.dart
// FILE PATH: lib/screens/story_view_screen.dart
// ===============================

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/stories_service.dart';

class StoryViewScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryViewScreen({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  final StoriesService _service = StoriesService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Timer logic
  double _currentAnimationValue = 0.0;
  Timer? _timer;
  bool _isPaused = false;

  // Local state for UI
  bool _isLiked = false; // Just visual for now

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _startTimer();
    _markAsViewed();
  }

  void _markAsViewed() {
    _service.viewStory(widget.stories[_currentIndex].id);
  }

  void _startTimer() {
    _timer?.cancel();
    _currentAnimationValue = 0.0;
    // 5 seconds per story
    const duration = Duration(seconds: 5);
    const step = Duration(milliseconds: 50);
    final totalSteps = duration.inMilliseconds / step.inMilliseconds;
    final increment = 1.0 / totalSteps;

    _timer = Timer.periodic(step, (timer) {
      if (!_isPaused) {
        setState(() {
          _currentAnimationValue += increment;
          if (_currentAnimationValue >= 1.0) {
            _nextStory();
          }
        });
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
        _currentAnimationValue = 0.0;
        _isLiked = false; // Reset like for new story
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      _startTimer();
      _markAsViewed();
    } else {
      _timer?.cancel();
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentAnimationValue = 0.0;
        _isLiked = false;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      _startTimer();
    } else {
      // Restart current story
      setState(() => _currentAnimationValue = 0.0);
    }
  }

  // --- DELETE LOGIC (Moved to Three-Dot Menu) ---
  Future<void> _deleteCurrentStory() async {
    setState(() => _isPaused = true); // Pause timer

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "Delete Story?",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "This cannot be undone.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _service.deleteStory(widget.stories[_currentIndex].id);
      if (mounted) Navigator.pop(context); // Close viewer after delete
    } else {
      setState(() => _isPaused = false); // Resume timer
    }
  }

  void _onTapDown(TapDownDetails details) {
    final width = MediaQuery.of(context).size.width;
    if (details.globalPosition.dx < width / 3) {
      _previousStory();
    } else {
      _nextStory();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStory = widget.stories[_currentIndex];
    final isMyStory = currentStory.userId == _currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: _onTapDown,
        onLongPressStart: (_) => setState(() => _isPaused = true),
        onLongPressEnd: (_) => setState(() => _isPaused = false),
        child: Stack(
          children: [
            // 1. The Image (Full Screen)
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: widget.stories[index].imageUrl,
                  fit:
                      BoxFit
                          .contain, // Keep aspect ratio, fill black bars if needed
                  errorWidget:
                      (c, u, e) => const Center(
                        child: Icon(Icons.error, color: Colors.white),
                      ),
                  placeholder:
                      (c, u) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                );
              },
            ),

            // 2. Gradient Overlay (Top) for text visibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
              ),
            ),

            // 3. Gradient Overlay (Bottom) for input visibility
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
            ),

            // 4. Progress Bars (Segmented)
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: LinearProgressIndicator(
                        value:
                            index < _currentIndex
                                ? 1.0
                                : (index == _currentIndex
                                    ? _currentAnimationValue
                                    : 0.0),
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        minHeight: 2.5,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // 5. Header (User Info & Menu)
            Positioned(
              top: 65,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(currentStory.userImage),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    currentStory.userName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    // Simple time display logic
                    "${DateTime.now().difference(currentStory.timestamp.toDate()).inHours}h",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  // Three-dot menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.white),
                    color: Colors.grey[900],
                    onSelected: (value) {
                      if (value == 'delete') _deleteCurrentStory();
                    },
                    itemBuilder:
                        (context) => [
                          if (isMyStory)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            const PopupMenuItem(
                              value: 'report',
                              child: Text(
                                'Report',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                        ],
                  ),
                ],
              ),
            ),

            // 6. Footer (Message & Like)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Send Message Pill
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(24),
                        color: Colors.transparent,
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Send Message",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Like Button
                  GestureDetector(
                    onTap: () {
                      setState(() => _isLiked = !_isLiked);
                      // Add actual like logic here if needed
                    },
                    child: AnimatedScale(
                      scale: _isLiked ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  // Optional: Send/Share Icon
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.send_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
