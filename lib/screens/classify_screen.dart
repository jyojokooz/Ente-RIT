import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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

// --- Widget Imports ---
import '../widgets/reusable_bottom_app_bar.dart';
import '../widgets/category_card.dart';

class ClassifyScreen extends StatelessWidget {
  const ClassifyScreen({super.key});

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
    // Define the color palette for consistency.
    final Color cardColor = Colors.grey.shade900;
    const Color secondaryTextColor = Colors.white70;
    const Color primaryAccentColor = Colors.yellow;
    const Color buttonTextColor = Colors.black;

    // A list of all categories/features available on this screen.
    final List<Map<String, dynamic>> categories = [
      {
        'label': 'Department Notes',
        'icon': Icons.school,
        'color': Colors.blue.shade600,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DepartmentsScreen(),
              ),
            ),
      },
      {
        'label': 'Events',
        'icon': Icons.calendar_today,
        'color': Colors.pink.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EventListScreen()),
            ),
      },
      {
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
        'label': 'Digital ID',
        'icon': Icons.badge_outlined,
        'color': Colors.green.shade500,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IdCardScreen()),
            ),
      },
      {
        'label': 'Connect AI',
        'icon': Icons.auto_awesome,
        'color': Colors.purple.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AiChatHistoryScreen(),
              ),
            ),
      },
      {
        'label': 'Code Playground',
        'icon': Icons.code,
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
        'label': 'Dev Community',
        'icon': Icons.question_answer_outlined,
        'color': Colors.orange.shade600,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DevCommunityScreen(),
              ),
            ),
      },
      {
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
      {
        'label': 'Lost & Found',
        'icon': Icons.find_in_page_outlined,
        'color': Colors.brown.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LostAndFoundScreen(),
              ),
            ),
      },
      {
        'label': 'Peer Rooms',
        'icon': Icons.group_outlined,
        'color': Colors.cyan.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PeerRoomsScreen()),
            ),
      },
      {
        'label': 'Marketplace',
        'icon': Icons.storefront_outlined,
        'color': Colors.amber.shade700,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MarketplaceScreen(),
              ),
            ),
      },
      {
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
        'label': 'No-Note',
        'icon': Icons.note_alt_outlined,
        'color': Colors.red.shade400,
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
                'Classify',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explore campus resources and categories',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      label: category['label'],
                      icon: category['icon'],
                      color: category['color'],
                      cardColor: cardColor,
                      textColor: secondaryTextColor,
                      onTap: category['action'],
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
