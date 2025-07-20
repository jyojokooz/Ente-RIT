import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'web_view_screen.dart'; // <-- Import the new screen

class DepartmentsScreen extends StatelessWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Departments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('departments')
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No departments found.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }
          final departments = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.0,
            ),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final dept = departments[index];
              final deptData = dept.data() as Map<String, dynamic>;
              final String departmentName = deptData['name'] ?? 'No Name';

              return CategoryCard(
                label: departmentName,
                icon: Icons.school_outlined,
                color: Colors.blue.shade400,
                cardColor: Colors.grey.shade900,
                textColor: Colors.white70,
                onTap: () {
                  // --- THIS IS THE NEW LOGIC ---
                  // Check if the department name is "MCA" (case-insensitive)
                  if (departmentName.toLowerCase() == 'mca') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const WebViewScreen(
                              title: 'MCA Department',
                              url: 'https://techworldthink.github.io/MCA/',
                            ),
                      ),
                    );
                  } else {
                    // For all other departments, just show a message for now
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on $departmentName')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Reusable CategoryCard widget
class CategoryCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color textColor;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
    this.onTap,
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
    _controller.reverse().then((_) {
      if (widget.onTap != null) {
        widget.onTap!();
      }
    });
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
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
