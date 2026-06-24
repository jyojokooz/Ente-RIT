import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeLeaderboardScreen extends StatefulWidget {
  const CollegeLeaderboardScreen({super.key});

  @override
  State<CollegeLeaderboardScreen> createState() => _CollegeLeaderboardScreenState();
}

class _CollegeLeaderboardScreenState extends State<CollegeLeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _gameIds = ['flappy_rit', '2048'];
  final List<String> _gameNames = ['Flappy RIT', '2048 Puzzle'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _gameIds.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'College Leaderboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE040FB),
          labelColor: const Color(0xFFE040FB),
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: _gameNames.map((name) => Tab(text: name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _gameIds.map((gameId) {
          return _LeaderboardView(
            gameId: gameId,
            cardColor: cardColor,
            textColor: textColor,
            isDark: isDark,
          );
        }).toList(),
      ),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  final String gameId;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  const _LeaderboardView({
    required this.gameId,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // To get the best scores per user, we ideally group in Cloud Functions.
    // For simplicity without functions, we just query top scores globally.
    // In a real app with high traffic, this might show the same user multiple times.
    // But since we update on game over only if > high score, it works out if we only push high scores.
    final query = FirebaseFirestore.instance
        .collection('game_scores')
        .where('gameId', isEqualTo: gameId)
        .orderBy('score', descending: true)
        .limit(50);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFE040FB)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load leaderboard.\nCheck Firestore permissions.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                const SizedBox(height: 16),
                Text('No scores yet!', style: GoogleFonts.poppins(color: textColor, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final userName = data['userName'] ?? 'Anonymous';
            final score = data['score'] ?? 0;
            final rank = index + 1;

            Color rankColor;
            if (rank == 1) {
              rankColor = const Color(0xFFFFD700); // Gold
            } else if (rank == 2) {
              rankColor = const Color(0xFFC0C0C0); // Silver
            } else if (rank == 3) {
              rankColor = const Color(0xFFCD7F32); // Bronze
            } else {
              rankColor = isDark ? Colors.white24 : Colors.black26;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '#$rank',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: rank <= 3 ? rankColor : textColor.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rank <= 3 ? rankColor.withOpacity(0.2) : (isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: Icon(
                      rank <= 3 ? Icons.emoji_events_rounded : Icons.person_rounded,
                      color: rank <= 3 ? rankColor : (isDark ? Colors.white54 : Colors.black54),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '$score',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFFE040FB),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
