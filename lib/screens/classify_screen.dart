import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'departments_screen.dart'; // <-- Import the new screen and the reusable CategoryCard

class ClassifyScreen extends StatelessWidget {
  const ClassifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.black;
    const Color headerColor = Colors.yellow;
    final Color cardColor = Colors.grey.shade900;
    const Color secondaryTextColor = Colors.white70;

    // We add a special "Departments" card to the top of our static list
    final List<Map<String, dynamic>> categories = [
      {
        'label': 'Departments',
        'icon': Icons.school,
        'color': Colors.blue.shade600,
        'isDepartment': true, // A flag to identify this special card
      },
      {
        'label': 'Transport',
        'icon': Icons.directions_bus,
        'color': Colors.purple.shade500,
      },
      {
        'label': 'Shopping',
        'icon': Icons.shopping_bag,
        'color': Colors.pink.shade400,
      },
      {
        'label': 'Bills',
        'icon': Icons.receipt,
        'color': Colors.orange.shade600,
      },
      {
        'label': 'Entertainment',
        'icon': Icons.movie,
        'color': Colors.red.shade500,
      },
      {
        'label': 'Grocery',
        'icon': Icons.local_grocery_store,
        'color': Colors.green.shade600,
      },
      {
        'label': 'Food',
        'icon': Icons.restaurant,
        'color': Colors.deepOrange.shade400,
      },
      {'label': 'Health', 'icon': Icons.healing, 'color': Colors.teal.shade400},
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
                      color: Colors.black.withAlpha((255 * 0.8).toInt()),
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
                          onTap: () {
                            // Use our flag to decide where to navigate
                            if (category['isDepartment'] == true) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const DepartmentsScreen(),
                                ),
                              );
                            } else {
                              // Handle other card taps if you need to
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tapped on ${category['label']}',
                                  ),
                                  duration: const Duration(seconds: 1),
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
          ),
        ],
      ),
    );
  }
}

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
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
