// ===============================
// FILE NAME: staff_profile_screen.dart
// FILE PATH: lib/features/campus/presentation/department_sub_screens/staff_profile_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/campus/data/rit_scraper_service.dart';
// --- IMPORT THE MEDIA VIEWER CONNECTOR ---
import 'package:my_project/core/widgets/media_viewers/media_viewers_connector.dart';

class StaffProfileScreen extends StatelessWidget {
  final int staffId;
  const StaffProfileScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    final RitScraperService scraper = RitScraperService();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: FutureBuilder<StaffProfileModel?>(
        future: scraper.fetchStaffProfile(staffId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFB165FF)),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                "Profile details unavailable.",
                style: TextStyle(color: textColor),
              ),
            );
          }

          final profile = snapshot.data!;

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              physics: const BouncingScrollPhysics(),
              headerSliverBuilder:
                  (context, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => FullScreenImageViewer(
                                            imageUrl: profile.photoUrl,
                                            heroTag: 'staff_full_$staffId',
                                            postId: null, // Fixed: No Dummy ID
                                          ),
                                    ),
                                  ),
                              child: Hero(
                                tag: 'staff_full_$staffId',
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFB165FF),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundImage: CachedNetworkImageProvider(
                                      profile.photoUrl,
                                    ),
                                    backgroundColor:
                                        isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              profile.name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.designation,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFB165FF),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (profile.email.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? Colors.white10
                                            : Colors.black12,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.email_outlined,
                                      size: 16,
                                      color: subtitleColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      profile.email,
                                      style: GoogleFonts.poppins(
                                        color: textColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          labelColor: const Color(0xFFB165FF),
                          unselectedLabelColor: subtitleColor,
                          indicatorColor: const Color(0xFFB165FF),
                          indicatorWeight: 3,
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          tabs: const [
                            Tab(text: "Education"),
                            Tab(text: "Experience"),
                          ],
                        ),
                        bgColor,
                      ),
                      pinned: true,
                    ),
                  ],
              body: TabBarView(
                children: [
                  // Education Tab
                  profile.education.isEmpty
                      ? Center(
                        child: Text(
                          "No education info added.",
                          style: TextStyle(color: subtitleColor),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: profile.education.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final edu = profile.education[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF9A44,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    color: Color(0xFFFF9A44),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        edu['degree']!,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        edu['university']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        edu['year']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? Colors.white30
                                                  : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  // Experience Tab
                  profile.experience.isEmpty
                      ? Center(
                        child: Text(
                          "No experience info added.",
                          style: TextStyle(color: subtitleColor),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        physics: const BouncingScrollPhysics(),
                        itemCount: profile.experience.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final exp = profile.experience[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00C6FB,
                                    ).withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.work_rounded,
                                    color: Color(0xFF00C6FB),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exp['designation']!,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        exp['institution']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: subtitleColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        exp['period']!,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isDark
                                                  ? Colors.white30
                                                  : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;
  _SliverAppBarDelegate(this._tabBar, this._bgColor);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _bgColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
