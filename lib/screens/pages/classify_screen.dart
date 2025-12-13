// ===============================
// FILE NAME: classify_screen.dart
// FILE PATH: lib/screens/pages/classify_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Import the centralized config
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
    const Color brandBlack = Colors.black;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Very light grey background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tools & Utilities',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: brandBlack,
                    ),
                  ),
                  Text(
                    'Explore what\'s available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // --- DYNAMIC GRID CONTENT ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // FIX: Removed 'where' clause. We fetch all and filter in Dart.
                // This avoids needing a composite index immediately.
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
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    );
                  }

                  // 1. Get all docs
                  final allDocs = snapshot.data!.docs;

                  // 2. Filter locally for isVisible == true
                  final visibleDocs =
                      allDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return data['isVisible'] == true;
                      }).toList();

                  if (visibleDocs.isEmpty) {
                    return Center(
                      child: Text(
                        "No tools enabled yet.\nAsk Admin to enable features.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: Colors.black,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 Columns
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.3, // Wider cards
                          ),
                      itemCount: visibleDocs.length,
                      itemBuilder: (context, index) {
                        final doc = visibleDocs[index];
                        final id = doc.id;

                        // Look up the static configuration for this ID
                        final config = FeatureConfig.featureMap[id];

                        // If configuration exists in code
                        if (config != null) {
                          return _ModernFeatureCard(
                            label: config['label'],
                            icon: config['icon'],
                            color: config['color'],
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
                          // Fallback if ID is in DB but not in Code (e.g. old version)
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

// --- CUSTOM MODERN CARD WIDGET ---
class _ModernFeatureCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernFeatureCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container with subtle background
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Light pastel version of color
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color, // The main vibrant color
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
