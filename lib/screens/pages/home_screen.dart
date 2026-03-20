import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../stories/stories_connector.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/home_banner_carousel.dart'; // <--- IMPORT NEW BANNER
import '../../widgets/home/home_upcoming_event_banner.dart';
import '../../widgets/home/home_post_feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  String _displayName = 'User';

  // Edge swipe detection variables
  double _startX = 0.0;
  double _startY = 0.0;
  bool _isSwiping = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    if (doc.exists && mounted) {
      setState(() {
        _displayName = doc.data()?['displayName'] ?? 'User';
      });
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Listener(
        onPointerDown: (event) {
          _startX = event.position.dx;
          _startY = event.position.dy;
          _isSwiping = true;
        },
        onPointerUp: (event) {
          if (!_isSwiping) return;

          final dx = event.position.dx - _startX;
          final dy = (event.position.dy - _startY).abs();

          // Swipe logic for stories
          if (dx > 40 && dy < 60 && _startX < 100) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (context, animation, secondaryAnimation) =>
                        const StoryCreatorScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  );
                },
              ),
            );
          }
          _isSwiping = false;
        },
        child: RefreshIndicator(
          onRefresh: _refreshPosts,
          color: const Color(0xFFFF3E8E),
          backgroundColor: cardColor,
          child: SafeArea(
            child: CustomScrollView(
              cacheExtent: 1000,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: HomeHeader(
                    displayName: _displayName,
                    isDark: isDark,
                    textColor: textColor,
                  ),
                ),

                // --- NEW SLIDING AD BANNER ---
                SliverToBoxAdapter(child: HomeBannerCarousel(isDark: isDark)),

                // Stories Bar
                const SliverToBoxAdapter(child: StoriesBar()),

                // Upcoming Event Banner
                SliverToBoxAdapter(
                  child: HomeUpcomingEventBanner(
                    isDark: isDark,
                    cardColor: cardColor,
                  ),
                ),

                // Post Feed
                HomePostFeed(textColor: textColor),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
