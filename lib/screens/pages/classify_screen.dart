import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/feature_config.dart';

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  Future<void> _handleRefresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tools & Utilities',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore what\'s available on campus',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),

            // --- DYNAMIC GRID CONTENT ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('features')
                        .orderBy('order')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          "Error loading tools: ${snapshot.error}",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: subtitleColor),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF3E8E),
                      ), // Pink loading indicator
                    );
                  }

                  final allDocs = snapshot.data!.docs;
                  final visibleDocs =
                      allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['isVisible'] == true;
                      }).toList();

                  if (visibleDocs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.construction,
                            size: 60,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No tools enabled yet.\nAsk Admin to enable features.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(color: subtitleColor),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: const Color(0xFFFF3E8E),
                    backgroundColor:
                        isDark ? const Color(0xFF252528) : Colors.white,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      // --- UPDATED GRID DELEGATE ---
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 items per row
                        crossAxisSpacing: 12, // Reduced spacing
                        mainAxisSpacing: 12, // Reduced spacing
                        childAspectRatio:
                            0.8, // Adjusted to 0.8 for slightly taller cards preventing overflow
                      ),
                      itemCount: visibleDocs.length,
                      itemBuilder: (context, index) {
                        final id = visibleDocs[index].id;
                        final config = FeatureConfig.featureMap[id];

                        if (config != null) {
                          return _ModernFeatureCard(
                            label: config['label'],
                            icon: config['icon'],
                            color: config['color'],
                            isDark: isDark,
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
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CUSTOM MODERN CARD WIDGET (UPDATED FOR SMALLER SIZE) ---
class _ModernFeatureCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernFeatureCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ModernFeatureCard> createState() => _ModernFeatureCardState();
}

class _ModernFeatureCardState extends State<_ModernFeatureCard>
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = widget.isDark ? Colors.white : Colors.black87;

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
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24), // Reduced rounding
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container with vibrant tinted background
              Container(
                height: 48, // Reduced height
                width: 48, // Reduced width
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15), // Tinted background
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color, // Vibrant icon color
                  size: 24, // Reduced icon size
                ),
              ),
              const SizedBox(height: 8), // Reduced spacing
              // Label wrapped in flexible to prevent any strict strict boundaries from overflowing
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                  ), // Reduced padding
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11, // Reduced font size
                      fontWeight: FontWeight.w500, // Slightly less bold
                      color: textColor,
                      height: 1.2,
                    ),
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
