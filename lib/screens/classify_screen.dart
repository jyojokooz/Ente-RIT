// --- FIX: REMOVED UNNECESSARY 'dart:ui' IMPORT ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ClassifyScreen extends StatelessWidget {
  const ClassifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Colors.black;
    const Color headerColor = Colors.yellow;
    final Color cardColor = Colors.grey.shade900;
    // --- FIX: REMOVED UNUSED 'primaryTextColor' VARIABLE ---
    const Color secondaryTextColor = Colors.white70;

    final List<Map<String, dynamic>> categories = [
      {'label': 'General', 'icon': Icons.apps, 'color': Colors.blue.shade600},
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
      {'label': 'Home', 'icon': Icons.home, 'color': Colors.brown.shade400},
      {
        'label': 'Education',
        'icon': Icons.school,
        'color': Colors.indigo.shade400,
      },
      {
        'label': 'Gifts',
        'icon': Icons.card_giftcard,
        'color': Colors.cyan.shade400,
      },
      {
        'label': 'Other',
        'icon': Icons.more_horiz,
        'color': Colors.grey.shade500,
      },
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
                    'Classify transaction',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Classify this transaction into a\nparticular category',
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

class CategoryCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color textColor;

  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: widget.color.withAlpha(50),
                child: Icon(widget.icon, size: 28, color: widget.color),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: GoogleFonts.poppins(
                  color: widget.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
