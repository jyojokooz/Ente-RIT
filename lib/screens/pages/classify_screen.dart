// lib/pages/classify_screen.dart

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

// --- Widget Imports ---
import '../../widgets/feature_card.dart';

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  Map<String, String> _cardBackgrounds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBackgroundImages();
  }

  // This method correctly fetches all image URLs from Firestore.
  Future<void> _fetchBackgroundImages() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('card_backgrounds').get();
      final Map<String, String> loadedImages = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('imageUrl') &&
            data['imageUrl'] != null &&
            data['imageUrl'].isNotEmpty) {
          loadedImages[doc.id] = data['imageUrl'];
        }
      }
      if (mounted) {
        setState(() {
          _cardBackgrounds = loadedImages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load card images: $e")),
        );
      }
    }
  }

  Future<void> _launchURLInBrowser(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (context.mounted) {
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
    // This feature list is the source of truth for the screen's content.
    final List<Map<String, dynamic>> features = [
      {
        'id': 'department_notes',
        'label': 'Department Notes',
        'icon': Icons.school_outlined,
        'color': const Color(0xFF2E86DE),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DepartmentsScreen(),
              ),
            ),
      },
      {
        'id': 'events',
        'label': 'Events',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFFE040FB),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventListScreen()),
            ),
      },
      {
        'id': 'lost_and_found',
        'label': 'Lost & Found',
        'icon': Icons.find_in_page_outlined,
        'color': const Color(0xFFF48C06),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LostAndFoundScreen(),
              ),
            ),
      },
      {
        'id': 'marketplace',
        'label': 'Marketplace',
        'icon': Icons.storefront_outlined,
        'color': const Color(0xFF38B000),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MarketplaceScreen(),
              ),
            ),
      },
      {
        'id': 'cafeteria',
        'label': 'Cafeteria',
        'icon': Icons.restaurant_menu_outlined,
        'color': const Color(0xFFD98E04),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CafeteriaScreen()),
            ),
      },
      {
        'id': 'bus_tracker',
        'label': 'Bus Tracker',
        'icon': Icons.directions_bus_outlined,
        'color': Colors.blue.shade600,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BusListScreen()),
            ),
      },
      {
        'id': 'connect_ai',
        'label': 'Connect AI',
        'icon': Icons.auto_awesome_outlined,
        'color': const Color(0xFF6A00F4),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AiChatHistoryScreen(),
              ),
            ),
      },
      {
        'id': 'peer_rooms',
        'label': 'Peer Rooms',
        'icon': Icons.group_outlined,
        'color': const Color(0xFF00B4D8),
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeerRoomsScreen()),
            ),
      },
      {
        'id': 'nonote',
        'label': 'No-Note',
        'icon': Icons.note_alt_outlined,
        'color': const Color(0xFFD00000),
        'action': () => _launchURLInBrowser(context, 'https://nonote.tech'),
      },
      {
        'id': 'digital_id',
        'label': 'Digital ID',
        'icon': Icons.badge_outlined,
        'color': Colors.green.shade600,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IdCardScreen()),
            ),
      },
      {
        'id': 'code_playground',
        'label': 'Code Playground',
        'icon': Icons.code_outlined,
        'color': Colors.indigo.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CodePlaygroundScreen(),
              ),
            ),
      },
      {
        'id': 'dev_community',
        'label': 'Stack Overflow',
        'icon': Icons.question_answer_outlined,
        'color': Colors.orange.shade700,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DevCommunityScreen(),
              ),
            ),
      },
      {
        'id': 'quiz',
        'label': 'Programming Quiz',
        'icon': Icons.quiz_outlined,
        'color': Colors.deepOrange.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuizCategoriesScreen(),
              ),
            ),
      },
      {
        'id': 'pdf_buddy',
        'label': 'PDF Study Buddy',
        'icon': Icons.picture_as_pdf_outlined,
        'color': Colors.indigo.shade300,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PdfBuddyScreen()),
            ),
      },
      {
        'id': 'resume_analyzer',
        'label': 'AI Resume Analyzer',
        'icon': Icons.document_scanner_outlined,
        'color': Colors.teal.shade600,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ResumeAnalyzerScreen(),
              ),
            ),
      },
      {
        'id': 'youtube_summarizer',
        'label': 'YouTube Summarizer',
        'icon': Icons.ondemand_video_outlined,
        'color': Colors.red.shade700,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const YouTubeSummarizerScreen(),
              ),
            ),
      },
      {
        'id': 'tech_news',
        'label': 'Tech News',
        'icon': Icons.newspaper_outlined,
        'color': Colors.grey.shade600,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TechNewsScreen()),
            ),
      },
      {
        'id': 'games',
        'label': 'Games',
        'icon': Icons.gamepad_outlined,
        'color': Colors.teal.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const GameViewScreen(
                      title: 'Smash Karts',
                      url: 'https://poki.com/en/g/smash-karts',
                    ),
              ),
            ),
      },
      {
        'id': 'etlab',
        'label': 'RIT ETLab',
        'icon': Icons.computer_outlined,
        'color': Colors.lightBlue.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EtlabWebviewScreen(),
              ),
            ),
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Campus Connect',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore tools and resources',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: features.length,
                        itemBuilder: (context, index) {
                          final feature = features[index];
                          final featureId = feature['id'];
                          // This line correctly finds the URL from the map we fetched.
                          final imageUrl = _cardBackgrounds[featureId];

                          // Now we pass the URL to our updated FeatureCard.
                          return FeatureCard(
                            label: feature['label'],
                            icon: feature['icon'],
                            color: feature['color'],
                            imageUrl: imageUrl,
                            onTap: feature['action'],
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
