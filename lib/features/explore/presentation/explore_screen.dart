// ===============================
// FILE NAME: explore_screen.dart
// FILE PATH: lib/features/explore/presentation/explore_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:my_project/features/explore/presentation/search_screen.dart';
import 'package:my_project/features/profile/presentation/requests_screen.dart';
import 'package:my_project/features/profile/presentation/find_friends_screen.dart';

// --- WIDGET IMPORTS ---
import 'package:my_project/features/explore/presentation/widgets/explore_search_bar.dart';
import 'package:my_project/features/explore/presentation/widgets/explore_menu_tile.dart';
import 'package:my_project/features/explore/presentation/widgets/explore_trending_grid.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Explore',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 24,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. SEARCH BAR & HEADER ACTIONS ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Component 1: Search Bar
                  ExploreSearchBar(
                    cardColor: cardColor,
                    subtitleColor: subtitleColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Component 2: Menu Tiles
                  ExploreMenuTile(
                    icon: Icons.people_alt_outlined,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFFB165FF),
                    title: "Find Friends",
                    subtitle: "Connect with people you may know",
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    cardColor: cardColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FindFriendsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  ExploreMenuTile(
                    icon: Icons.person_add_alt_1_outlined,
                    iconColor: Colors.white,
                    iconBgColor: const Color(0xFF00C6FB),
                    title: "Connection Requests",
                    subtitle: "View pending requests",
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    cardColor: cardColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RequestsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Trending Header
                  Text(
                    'Trending Posts',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // --- 2. TRENDING POSTS GRID ---
          if (user == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData)
                  return const SliverToBoxAdapter(child: SizedBox.shrink());

                final myData =
                    userSnap.data!.data() as Map<String, dynamic>? ?? {};
                final List<dynamic> myConnections = myData['connections'] ?? [];

                // Component 3: Explore Grid
                return ExploreTrendingGrid(
                  currentUserId: user!.uid,
                  myConnections: myConnections,
                  cardColor: cardColor,
                  subtitleColor: subtitleColor,
                  isDark: isDark,
                );
              },
            ),
        ],
      ),
    );
  }
}
