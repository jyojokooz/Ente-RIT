import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/reusable_bottom_app_bar.dart'; // Import the new reusable widget
import 'departments_screen.dart';
import 'game_view_screen.dart';
import 'create_post_screen.dart';

class ClassifyScreen extends StatelessWidget {
  const ClassifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Colors.grey.shade900;
    const Color secondaryTextColor = Colors.white70;
    const Color primaryAccentColor = Colors.yellow;
    const Color buttonTextColor = Colors.black;

    // The list of categories for the grid
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
        'label': 'Transport',
        'icon': Icons.directions_bus,
        'color': Colors.purple.shade500,
        'action':
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tapped on Transport')),
            ),
      },
      {
        'label': 'Shopping',
        'icon': Icons.shopping_bag,
        'color': Colors.pink.shade400,
        'action':
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Tapped on Shopping'))),
      },
      {
        'label': 'Bills',
        'icon': Icons.receipt,
        'color': Colors.orange.shade600,
        'action':
            () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Tapped on Bills'))),
      },
      {
        'label': 'Entertainment',
        'icon': Icons.movie,
        'color': Colors.red.shade500,
        'action':
            () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tapped on Entertainment')),
            ),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      // --- ADDED THE FLOATINGACTIONBUTTON AND BOTTOMAPPBAR ---
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

      // The body is now a simpler layout without the custom header
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main screen title
              Text(
                'Classify',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Explore campus resources and categories',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Grid view to show the categories
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(top: 10),
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

// The CategoryCard widget is now imported from departments_screen.dart,
// so it is no longer needed here. We assume it's in the other file.
