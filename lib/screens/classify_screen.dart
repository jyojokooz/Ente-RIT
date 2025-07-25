import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'departments_screen.dart';
import 'game_view_screen.dart'; // <-- 1. IMPORT THE NEW GAME SCREEN

class ClassifyScreen extends StatelessWidget {
  const ClassifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.black;
    const Color headerColor = Colors.yellow;
    final Color cardColor = Colors.grey.shade900;
    const Color secondaryTextColor = Colors.white70;

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
      // --- 2. ADD THE NEW "GAMES" CARD DATA ---
      {
        'label': 'Games',
        'icon': Icons.gamepad_outlined,
        'color': Colors.teal.shade400,
        'action':
            () => Navigator.push(
              context,
              MaterialPageRoute(
                // We are linking to a popular, high-quality multiplayer web game
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
      // ... Add more categories as needed
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(height: 300, color: headerColor),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Back',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Classify',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore campus resources\nand categories',
                    style: GoogleFonts.poppins(
                      color: Colors.black.withAlpha(204),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(top: 10),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
                          // --- 3. USE THE 'action' FUNCTION FOR ONTAP ---
                          onTap: category['action'],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// HeaderClipper is unchanged
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
