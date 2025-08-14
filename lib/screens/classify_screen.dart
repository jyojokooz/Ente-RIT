import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/reusable_bottom_app_bar.dart';
import '../widgets/category_card.dart';
import 'departments_screen.dart';
import 'game_view_screen.dart';
import 'create_post_screen.dart';
import 'id_card_screen.dart';
import 'ai_chat_screen.dart';
import 'code_playground_screen.dart';
import 'dev_community_screen.dart';
import 'event_list_screen.dart'; // <-- 1. IMPORT THE EVENT LIST SCREEN

class ClassifyScreen extends StatelessWidget {
  const ClassifyScreen({super.key});

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
    final Color cardColor = Colors.grey.shade900;
    const Color secondaryTextColor = Colors.white70;
    const Color primaryAccentColor = Colors.yellow;
    const Color buttonTextColor = Colors.black;

    // --- 2. ADD THE "EVENTS" CARD BACK TO THE LIST ---
    final List<Map<String, dynamic>> categories = [
      {
        'label': 'Departments',
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
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
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
