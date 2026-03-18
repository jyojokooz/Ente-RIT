// ===============================
// FILE NAME: home_screen.dart
// FILE PATH: lib/screens/pages/home_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/stories_bar.dart';

// Import our new home components
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
    setState(() {}); // Triggers StreamBuilder rebuild in HomePostFeed
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom colors matching the design
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        color: const Color(0xFFFF3E8E),
        backgroundColor: cardColor,
        child: SafeArea(
          child: CustomScrollView(
            cacheExtent: 1000,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. TOP APP BAR & GREETING
              SliverToBoxAdapter(
                child: HomeHeader(
                  displayName: _displayName,
                  isDark: isDark,
                  textColor: textColor,
                ),
              ),

              // 2. FAKE INPUT BOX
              SliverToBoxAdapter(
                child: HomeCreatePostBar(
                  profilePic: _profilePic,
                  isDark: isDark,
                  cardColor: cardColor,
                ),
              ),

              // 3. STORIES BAR
              const SliverToBoxAdapter(child: StoriesBar()),

              // 4. SEGMENTED TABS
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

              // 5. POST FEED
              HomePostFeed(selectedTab: _selectedTab, textColor: textColor),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}
