// ===============================
// FILE NAME: classify_screen.dart
// FILE PATH: lib/screens/pages/classify_screen.dart
// ===============================

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
  Map<String, String> _cardBackgrounds = {};
  bool _isLoading = true;

  // FIX: Make nullable to prevent LateInitializationError during hot reloads/async gaps
  AnimationController? _controller;

  final List<Map<String, dynamic>> _features = [
    {
      'id': 'department_notes',
      'label': 'Notes',
      'icon': Icons.school_outlined,
      'color': Color(0xFF2E86DE),
      'screen': const DepartmentsScreen(),
    },
    {
      'id': 'events',
      'label': 'Events',
      'icon': Icons.calendar_today_outlined,
      'color': Color(0xFFE040FB),
      'screen': const EventListScreen(),
    },
    {
      'id': 'lost_and_found',
      'label': 'Lost & Found',
      'icon': Icons.find_in_page_outlined,
      'color': Color(0xFFF48C06),
      'screen': const LostAndFoundScreen(),
    },
    {
      'id': 'marketplace',
      'label': 'Market',
      'icon': Icons.storefront_outlined,
      'color': Color(0xFF38B000),
      'screen': const MarketplaceScreen(),
    },
    {
      'id': 'cafeteria',
      'label': 'Cafeteria',
      'icon': Icons.restaurant_menu_outlined,
      'color': Color(0xFFD98E04),
      'screen': const CafeteriaScreen(),
    },
    {
      'id': 'bus_tracker',
      'label': 'Bus',
      'icon': Icons.directions_bus_outlined,
      'color': Colors.blue,
      'screen': const BusListScreen(),
    },
    {
      'id': 'connect_ai',
      'label': 'AI Chat',
      'icon': Icons.auto_awesome_outlined,
      'color': Color(0xFF6A00F4),
      'screen': const AiChatHistoryScreen(),
    },
    {
      'id': 'peer_rooms',
      'label': 'Rooms',
      'icon': Icons.group_outlined,
      'color': Color(0xFF00B4D8),
      'screen': const PeerRoomsScreen(),
    },
    {
      'id': 'digital_id',
      'label': 'ID Card',
      'icon': Icons.badge_outlined,
      'color': Colors.green,
      'screen': const IdCardScreen(),
    },
    {
      'id': 'code_playground',
      'label': 'Code',
      'icon': Icons.code_outlined,
      'color': Colors.indigo,
      'screen': const CodePlaygroundScreen(),
    },
    {
      'id': 'dev_community',
      'label': 'Stack Overflow',
      'icon': Icons.question_answer_outlined,
      'color': Colors.orange,
      'screen': const DevCommunityScreen(),
    },
    {
      'id': 'quiz',
      'label': 'Quiz',
      'icon': Icons.quiz_outlined,
      'color': Colors.deepOrange,
      'screen': const QuizCategoriesScreen(),
    },
    {
      'id': 'pdf_buddy',
      'label': 'PDF Buddy',
      'icon': Icons.picture_as_pdf_outlined,
      'color': Colors.indigoAccent,
      'screen': const PdfBuddyScreen(),
    },
    {
      'id': 'resume_analyzer',
      'label': 'Resume AI',
      'icon': Icons.document_scanner_outlined,
      'color': Colors.teal,
      'screen': const ResumeAnalyzerScreen(),
    },
    {
      'id': 'youtube_summarizer',
      'label': 'YT Summary',
      'icon': Icons.ondemand_video_outlined,
      'color': Colors.red,
      'screen': const YouTubeSummarizerScreen(),
    },
    {
      'id': 'tech_news',
      'label': 'Tech News',
      'icon': Icons.newspaper_outlined,
      'color': Colors.grey,
      'screen': const TechNewsScreen(),
    },
    {
      'id': 'games',
      'label': 'Games',
      'icon': Icons.gamepad_outlined,
      'color': Colors.tealAccent,
      'screen': const GameViewScreen(
        title: 'Smash Karts',
        url: 'https://poki.com/en/g/smash-karts',
      ),
    },
    {
      'id': 'etlab',
      'label': 'ETLab',
      'icon': Icons.computer_outlined,
      'color': Colors.lightBlue,
      'screen': const EtlabWebviewScreen(),
    },
    {
      'id': 'nonote',
      'label': 'No-Note',
      'icon': Icons.note_alt_outlined,
      'color': Color(0xFFD00000),
      'url': 'https://nonote.tech',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize immediately
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fetchBackgroundImages();
  }

  @override
  void dispose() {
    // Safe dispose
    _controller?.dispose();
    super.dispose();
  }

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
        _controller?.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _controller?.forward();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Couldn't load images: $e")));
      }
    }
  }

  Future<void> _launchURL(String url) async {
    if (!await canLaunchUrl(Uri.parse(url))) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;

    // FIX: Safety check. If controller is null (during hot reload edge case), show loader.
    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: brandBlack)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                    'CAMPUS TOOLS',
                    style: GoogleFonts.archivoBlack(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: brandBlack,
                      letterSpacing: -1.5,
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 6,
                    color: const Color(0xFF9983F3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything you need in one place.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // --- GRID ---
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.1,
                            ),
                        itemCount: _features.length,
                        itemBuilder: (context, index) {
                          final feature = _features[index];
                          final imageUrl = _cardBackgrounds[feature['id']];

                          // Use ! because we checked for null at top of build
                          final Animation<double> animation = CurvedAnimation(
                            parent: _controller!,
                            curve: Interval(
                              (index / _features.length) * 0.5,
                              1.0,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: _NeoFeatureCard(
                                label: feature['label'],
                                icon: feature['icon'],
                                color: feature['color'],
                                imageUrl: imageUrl,
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
                              ),
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

// --- CUSTOM WIDGET: Neo-Brutalist Feature Card ---
class _NeoFeatureCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final VoidCallback onTap;

  const _NeoFeatureCard({
    required this.label,
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.onTap,
  });

  @override
  State<_NeoFeatureCard> createState() => _NeoFeatureCardState();
}

class _NeoFeatureCardState extends State<_NeoFeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const Color brandBlack = Colors.black;
    final bool hasImage =
        widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform:
            _isPressed
                ? Matrix4.translationValues(4, 4, 0)
                : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: brandBlack, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              _isPressed
                  ? []
                  : [
                    BoxShadow(
                      color: brandBlack,
                      offset: const Offset(6, 6),
                      blurRadius: 0,
                    ),
                  ],
          image:
              hasImage
                  ? DecorationImage(
                    image: NetworkImage(widget.imageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  )
                  : null,
        ),
        child: Stack(
          children: [
            if (!hasImage)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.bolt,
                  color: widget.color.withOpacity(0.2),
                  size: 60,
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          hasImage
                              ? Colors.white.withOpacity(0.9)
                              : widget.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: brandBlack, width: 2),
                    ),
                    child: Icon(
                      widget.icon,
                      color: hasImage ? brandBlack : widget.color,
                      size: 28,
                    ),
                  ),

                  Text(
                    widget.label.toUpperCase(),
                    style: GoogleFonts.archivoBlack(
                      fontSize: 16,
                      color: hasImage ? Colors.white : brandBlack,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      shadows:
                          hasImage
                              ? [
                                const Shadow(
                                  color: Colors.black,
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ]
                              : [],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
