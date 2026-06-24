// ===============================
// FILE NAME: classify_screen.dart
// FILE PATH: lib/features/campus/presentation/classify_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_project/core/config/feature_config.dart';

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // We are not using Firebase for the features list anymore since we're using feature_config directly
  // But we can add a fake refresh delay to keep the UI feel
  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    // Filter features
    final allFeatures = FeatureConfig.featureMap.entries.toList();
    final filteredFeatures = allFeatures.where((entry) {
      final data = entry.value;
      final label = (data['label'] as String).toLowerCase();
      final category = data['category'] as String?;

      final matchesSearch = label.contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF9983F3),
          backgroundColor: cardColor,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // --- HEADER & SEARCH ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore Campus',
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Discover tools, services & more',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9983F3).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              color: Color(0xFF9983F3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Modern Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        style: GoogleFonts.poppins(color: textColor, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search tools, places, events...',
                          hintStyle: GoogleFonts.poppins(color: subtitleColor),
                          filled: true,
                          fillColor: cardColor,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- FEATURED BANNER ---
              if (_searchQuery.isEmpty && _selectedCategory == 'All')
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: Text(
                          'Featured',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            _FeaturedCard(
                              title: 'GPA Calc',
                              subtitle: 'Calculate SGPA instantly',
                              icon: Icons.calculate_rounded,
                              color1: const Color(0xFF7B61FF),
                              color2: const Color(0xFFB165FF),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => FeatureConfig.featureMap['gpa_calculator']['screen']));
                              },
                            ),
                            _FeaturedCard(
                              title: 'Confessions',
                              subtitle: 'Share your secrets anonymously',
                              icon: Icons.chat_bubble_rounded,
                              color1: const Color(0xFFE040FB),
                              color2: const Color(0xFF9C27B0),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => FeatureConfig.featureMap['confession_box']['screen']));
                              },
                            ),
                            _FeaturedCard(
                              title: 'Campus Map',
                              subtitle: 'Navigate RIT effortlessly',
                              icon: Icons.map_rounded,
                              color1: const Color(0xFF2EC4B6),
                              color2: const Color(0xFF00B4D8),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => FeatureConfig.featureMap['campus_map']['screen']));
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // --- CATEGORY TABS ---
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: FeatureConfig.categories.length,
                    itemBuilder: (context, index) {
                      final cat = FeatureConfig.categories[index];
                      final isSelected = _selectedCategory == cat;

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = cat;
                          _searchQuery = '';
                          _searchController.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF9983F3) : cardColor,
                            borderRadius: BorderRadius.circular(22),
                            border: isDark && !isSelected
                                ? Border.all(color: Colors.white10)
                                : null,
                            boxShadow: [
                              if (!isDark && isSelected)
                                BoxShadow(
                                  color: const Color(0xFF9983F3).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isSelected ? Colors.white : subtitleColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // --- GRID ---
              filteredFeatures.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 64,
                              color: isDark ? Colors.white12 : Colors.black12,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No tools found.",
                              style: GoogleFonts.poppins(color: subtitleColor, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 120), // Padding for bottom nav bar
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 columns for wider cards with descriptions
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final config = filteredFeatures[index].value;

                            return AnimationConfiguration.staggeredGrid(
                              position: index,
                              duration: const Duration(milliseconds: 400),
                              columnCount: 2,
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _PremiumFeatureCard(
                                    label: config['label'],
                                    description: config['description'] ?? '',
                                    icon: config['icon'],
                                    color: config['color'],
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                    onTap: () {
                                      if (config.containsKey('url')) {
                                        _launchURL(config['url']);
                                      } else if (config.containsKey('screen')) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => config['screen'],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: filteredFeatures.length,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- PREMIUM FEATURE CARD WIDGET ---
class _PremiumFeatureCard extends StatefulWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _PremiumFeatureCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  State<_PremiumFeatureCard> createState() => _PremiumFeatureCardState();
}

class _PremiumFeatureCardState extends State<_PremiumFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isDark
                  ? widget.color.withOpacity(0.1)
                  : widget.color.withOpacity(0.05),
              width: 1.5,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: widget.color.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with gradient background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withOpacity(0.8),
                      widget.color.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const Spacer(),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: widget.subtitleColor,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- FEATURED BANNER CARD ---
class _FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color1;
  final Color color2;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color1,
    required this.color2,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color1, color2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color1.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Icon watermark
            Positioned(
              right: -10,
              bottom: -10,
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: Icon(
                  icon,
                  size: 100,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ),
            // Content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

