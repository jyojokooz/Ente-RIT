import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Screen Imports ---
import 'departments_screen.dart';
import 'game_view_screen.dart';
import 'create_post_screen.dart';
import 'id_card_screen.dart';
import 'ai_chat_history_screen.dart';
import 'code_playground_screen.dart';
import 'dev_community_screen.dart';
import 'event_list_screen.dart';
import 'peer_rooms_screen.dart';
import 'marketplace_screen.dart';
import 'tech_news_screen.dart';
import 'etlab_webview_screen.dart';
import 'lost_and_found_screen.dart';
import 'quiz_categories_screen.dart';
import 'pdf_buddy_screen.dart';
import 'linkedin_analyzer_screen.dart';
import 'youtube_summarizer_screen.dart';

// --- Widget Imports ---
import '../widgets/reusable_bottom_app_bar.dart';
import '../widgets/feature_card.dart'; // Make sure you have created this widget file

class ClassifyScreen extends StatefulWidget {
  const ClassifyScreen({super.key});

  @override
  State<ClassifyScreen> createState() => _ClassifyScreenState();
}

class _ClassifyScreenState extends State<ClassifyScreen> {
  // This map will store the fetched image URLs, mapping a card's ID to its URL.
  Map<String, String> _cardBackgrounds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBackgroundImages();
  }

  // Fetches image URLs from Firestore when the screen loads.
  Future<void> _fetchBackgroundImages() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('card_backgrounds').get();
      final Map<String, String> loadedImages = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        // Only add images that have a valid, non-empty URL
        if (data.containsKey('imageUrl') &&
            data['imageUrl'] != null &&
            data['imageUrl'].isNotEmpty) {
          loadedImages[doc.id] = data['imageUrl'];
        }
      }
      // Check if the widget is still mounted before updating the state
      if (mounted) {
        setState(() {
          _cardBackgrounds = loadedImages;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If there's an error, stop loading so the UI can build without images.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Optionally, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't load card images: $e")),
        );
      }
    }
  }

  /// A helper method to launch external URLs in the device's default browser.
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
    const Color primaryAccentColor = Colors.yellow;
    const Color buttonTextColor = Colors.black;

    // This is your original hardcoded list of features.
    // The 'id' MUST match the document ID in the 'card_backgrounds' collection.
    final List<Map<String, dynamic>> features = [
      {
        'id': 'department_notes',
        'label': 'Department Notes',
        'icon': Icons.school,
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
        'icon': Icons.calendar_today,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventListScreen()),
            ),
      },
      {
        'id': 'tech_news',
        'label': 'Tech News',
        'icon': Icons.newspaper_outlined,
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
        'id': 'digital_id',
        'label': 'Digital ID',
        'icon': Icons.badge_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IdCardScreen()),
            ),
      },
      {
        'id': 'connect_ai',
        'label': 'Connect AI',
        'icon': Icons.auto_awesome,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AiChatHistoryScreen(),
              ),
            ),
      },
      {
        'id': 'code_playground',
        'label': 'Code Playground',
        'icon': Icons.code,
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
        'label': 'Dev Community',
        'icon': Icons.question_answer_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DevCommunityScreen(),
              ),
            ),
      },
      {
        'id': 'etlab',
        'label': 'RIT ETLab',
        'icon': Icons.computer_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EtlabWebviewScreen(),
              ),
            ),
      },
      {
        'id': 'lost_and_found',
        'label': 'Lost & Found',
        'icon': Icons.find_in_page_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LostAndFoundScreen(),
              ),
            ),
      },
      {
        'id': 'peer_rooms',
        'label': 'Peer Rooms',
        'icon': Icons.group_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeerRoomsScreen()),
            ),
      },
      {
        'id': 'marketplace',
        'label': 'Marketplace',
        'icon': Icons.storefront_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MarketplaceScreen(),
              ),
            ),
      },
      {
        'id': 'quiz',
        'label': 'Programming Quiz',
        'icon': Icons.quiz_outlined,
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
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PdfBuddyScreen()),
            ),
      },
      {
        'id': 'linkedin_analyzer',
        'label': 'LinkedIn Analyzer',
        'icon': Icons.analytics_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LinkedInAnalyzerScreen(),
              ),
            ),
      },
      {
        'id': 'youtube_summarizer',
        'label': 'YouTube Summarizer',
        'icon': Icons.ondemand_video_outlined,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const YouTubeSummarizerScreen(),
              ),
            ),
      },
      {
        'id': 'nonote',
        'label': 'No-Note',
        'icon': Icons.note_alt_outlined,
        'action': () => _launchURLInBrowser(context, 'https://nonote.tech'),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreatePostScreen()),
            ),
        backgroundColor: primaryAccentColor,
        elevation: 4.0,
        child: const Icon(Icons.add, color: buttonTextColor, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const ReusableBottomAppBar(
        activeScreen: ActiveScreen.classify,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campus Connect',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore tools and resources',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                          padding: const EdgeInsets.only(top: 10, bottom: 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    2, // Your original 2-column layout
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: features.length,
                          itemBuilder: (context, index) {
                            final feature = features[index];
                            final featureId = feature['id'];
                            // Get the dynamic image URL from our state map.
                            // It will be null if no URL is set in Firestore.
                            final imageUrl = _cardBackgrounds[featureId];

                            return FeatureCard(
                              label: feature['label'],
                              icon: feature['icon'],
                              imageUrl: imageUrl, // Pass the dynamic image URL
                              onTap: feature['action'],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
