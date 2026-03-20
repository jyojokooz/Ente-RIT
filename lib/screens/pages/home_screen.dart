// ===============================
// FILE NAME: home_screen.dart
// FILE PATH: lib/screens/pages/home_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../stories/stories_connector.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/home_create_post_bar.dart';
import '../../widgets/home/home_tabs.dart';
import '../../widgets/home/home_post_feed.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  String _displayName = 'User';
  String _profilePic = '';
  int _selectedTab = 0; // 0: Recent, 1: Trending

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
        _profilePic = doc.data()?['profilePhotoUrl'] ?? '';
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

          // --- HIGHLY FORGIVING SWIPE LOGIC ---
          // 1. dx > 40 : Only requires a short 40-pixel swipe to the right.
          // 2. dy < 60 : Ensures it was mostly a horizontal swipe (not scrolling up/down).
          // 3. _startX < 100 : Allows the swipe to start anywhere in the left 100 pixels (very generous thumb area).
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
                SliverToBoxAdapter(
                  child: HomeCreatePostBar(
                    profilePic: _profilePic,
                    isDark: isDark,
                    cardColor: cardColor,
                  ),
                ),
                const SliverToBoxAdapter(child: StoriesBar()),
                SliverToBoxAdapter(
                  child: HomeTabs(
                    selectedTab: _selectedTab,
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                    isDark: isDark,
                    cardColor: cardColor,
                  ),
                ),
                HomePostFeed(selectedTab: _selectedTab, textColor: textColor),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
