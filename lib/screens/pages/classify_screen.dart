// ===============================
// FILE NAME: classify_screen.dart
// FILE PATH: lib/screens/pages/classify_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Screen Imports ---
import '../departments_screen.dart';
import '../game_view_screen.dart';
import '../id_card_screen.dart';
import '../ai_chat_history_screen.dart';
import '../code_playground_screen.dart';
import '../dev_community_screen.dart';
import '../event_list_screen.dart';
import '../peer_rooms_screen.dart';
import '../marketplace_screen.dart';
import '../tech_news_screen.dart';
import '../etlab_webview_screen.dart';
import '../lost_and_found_screen.dart';
import '../quiz_categories_screen.dart';
import '../pdf_buddy_screen.dart';
import '../resume_analyzer_screen.dart';
import '../youtube_summarizer_screen.dart';
import '../cafeteria_screen.dart';
import '../bus_list_screen.dart';

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;

  // We don't need to fetch card backgrounds anymore for this cleaner design,
  // but we keep the loading state just in case you want to fetch dynamic features later.

  final List<Map<String, dynamic>> _features = [
    {
      'label': 'Departments',
      'icon': Icons.school_rounded,
      'color': Color(0xFF4FACFE), // Blue Gradient Start
      'screen': const DepartmentsScreen(),
    },
    {
      'label': 'Events',
      'icon': Icons.calendar_month_rounded,
      'color': Color(0xFF43E97B), // Green Gradient Start
      'screen': const EventListScreen(),
    },
    {
      'label': 'Lost & Found',
      'icon': Icons.search_rounded,
      'color': Color(0xFFFA709A), // Pink Gradient Start
      'screen': const LostAndFoundScreen(),
    },
    {
      'label': 'Marketplace',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFFFFD200), // Yellow Gradient Start
      'screen': const MarketplaceScreen(),
    },
    {
      'label': 'Cafeteria',
      'icon': Icons.fastfood_rounded,
      'color': Color(0xFFF7971E), // Orange Gradient Start
      'screen': const CafeteriaScreen(),
    },
    {
      'label': 'Bus Tracker',
      'icon': Icons.directions_bus_rounded,
      'color': Color(0xFF30CFD0), // Teal Gradient Start
      'screen': const BusListScreen(),
    },
    {
      'label': 'Connect AI',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF667EEA), // Indigo Gradient Start
      'screen': const AiChatHistoryScreen(),
    },
    {
      'label': 'Peer Rooms',
      'icon': Icons.groups_rounded,
      'color': Color(0xFF00C6FB), // Light Blue
      'screen': const PeerRoomsScreen(),
    },
    {
      'label': 'Digital ID',
      'icon': Icons.badge_rounded,
      'color': Color(0xFF89F7FE), // Cyan
      'screen': const IdCardScreen(),
    },
    {
      'label': 'Code Lab',
      'icon': Icons.code_rounded,
      'color': Color(0xFF13547A), // Dark Blue
      'screen': const CodePlaygroundScreen(),
    },
    {
      'label': 'Dev Community',
      'icon': Icons.forum_rounded,
      'color': Color(0xFFF83600), // Orange/Red
      'screen': const DevCommunityScreen(),
    },
    {
      'label': 'Quiz',
      'icon': Icons.quiz_rounded,
      'color': Color(0xFFB721FF), // Purple
      'screen': const QuizCategoriesScreen(),
    },
    {
      'label': 'PDF Buddy',
      'icon': Icons.picture_as_pdf_rounded,
      'color': Color(0xFFF5576C), // Pinkish Red
      'screen': const PdfBuddyScreen(),
    },
    {
      'label': 'Resume AI',
      'icon': Icons.description_rounded,
      'color': Color(0xFF0BA360), // Green
      'screen': const ResumeAnalyzerScreen(),
    },
    {
      'label': 'YT Summary',
      'icon': Icons.play_circle_filled_rounded,
      'color': Color(0xFFFF0844), // Red
      'screen': const YouTubeSummarizerScreen(),
    },
    {
      'label': 'Tech News',
      'icon': Icons.newspaper_rounded,
      'color': Color(0xFF203A43), // Dark Grey
      'screen': const TechNewsScreen(),
    },
    {
      'label': 'Games',
      'icon': Icons.sports_esports_rounded,
      'color': Color(0xFF00CDAC), // Greenish Teal
      'screen': const GameViewScreen(
        title: 'Smash Karts',
        url: 'https://poki.com/en/g/smash-karts',
      ),
    },
    {
      'label': 'ETLab',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF3B2667), // Deep Purple
      'screen': const EtlabWebviewScreen(),
    },
    {
      'label': 'No-Note',
      'icon': Icons.note_alt_rounded,
      'color': Color(0xFFDA22FF), // Magenta
      'url': 'https://nonote.tech',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Simulate a quick load for smooth transition feel
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _launchURL(String url) async {
    if (!await canLaunchUrl(Uri.parse(url))) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
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
                  // Optional: Profile Icon or Settings here
                ],
              ),
            ),

            // --- GRID CONTENT ---
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                      : GridView.builder(
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
                        itemCount: _features.length,
                        itemBuilder: (context, index) {
                          final feature = _features[index];
                          return _ModernFeatureCard(
                            label: feature['label'],
                            icon: feature['icon'],
                            color: feature['color'],
                            onTap: () {
                              if (feature.containsKey('url')) {
                                _launchURL(feature['url']);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => feature['screen'],
                                  ),
                                );
                              }
                            },
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
              offset: const Offset(0, 4), // changes position of shadow
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
