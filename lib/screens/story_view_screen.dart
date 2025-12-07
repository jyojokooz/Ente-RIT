// ===============================
// FILE NAME: story_view_screen.dart
// FILE PATH: lib/screens/story_view_screen.dart
// ===============================

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart'; // Import Auth
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

class _StoryViewScreenState extends State<StoryViewScreen> {
  late int _currentIndex;
  late PageController _pageController;
  final StoriesService _service = StoriesService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Timer logic
  double _progress = 0.0;
  Timer? _timer;
  bool _isPaused = false; // To pause timer during dialogs

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
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPaused) {
        setState(() {
          _progress += 0.01;
          if (_progress >= 1.0) {
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

  // --- DELETE LOGIC ---
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
        onTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            // Logic to go back could be added here
          } else {
            _nextStory();
          }
        },
        // Pause on long press
        onLongPressStart: (_) => setState(() => _isPaused = true),
        onLongPressEnd: (_) => setState(() => _isPaused = false),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.stories.length,
              itemBuilder: (context, index) {
                return Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.stories[index].imageUrl,
                    fit: BoxFit.contain,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                  ),
                );
              },
            ),

            // Progress Bar
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.withOpacity(0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 2,
              ),
            ),

            // User Info Overlay
            Positioned(
              top: 50,
              left: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(currentStory.userImage),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currentStory.userName,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    // Simple time display logic
                    "${DateTime.now().difference(currentStory.timestamp.toDate()).inHours}h",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // --- DELETE BUTTON (Only if it's my story) ---
            if (isMyStory)
              Positioned(
                bottom: 40,
                right: 20,
                child: IconButton(
                  onPressed: _deleteCurrentStory,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
