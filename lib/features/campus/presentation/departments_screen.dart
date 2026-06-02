// ===============================
// FILE NAME: departments_screen.dart
// FILE PATH: lib/screens/departments_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/campus/presentation/department_detail_menu_screen.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Modern, vibrant gradients for the department badges
  final List<List<Color>> _gradients = [
    [const Color(0xFFB165FF), const Color(0xFFFF4B72)], // Purple to Pink
    [
      const Color(0xFF00C6FB),
      const Color(0xFF005BEA),
    ], // Light Blue to Deep Blue
    [const Color(0xFF43E97B), const Color(0xFF38F9D7)], // Green to Mint
    [const Color(0xFFFF9A44), const Color(0xFFFF3E8E)], // Orange to Pink
    [const Color(0xFFF5576C), const Color(0xFFF093FB)], // Red to Magenta
    [const Color(0xFF89F7FE), const Color(0xFF66A6FF)], // Sky Blue
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FIXED ACRONYM LOGIC ---
  String _getAcronym(String name) {
    if (name.isEmpty) return "";

    String lowerName = name.toLowerCase();

    // 1. Check for MCA first so "Computer Application" doesn't trigger CSE
    if (lowerName.contains("mca") || lowerName.contains("application")) {
      return "MCA";
    }

    // 2. Check for other standard engineering acronyms
    if (lowerName.contains("computer")) return "CSE";
    if (lowerName.contains("mechanical")) return "ME";
    if (lowerName.contains("electrical") && lowerName.contains("electronics")) {
      return "EEE";
    }
    if (lowerName.contains("electronics") &&
        lowerName.contains("communication")) {
      return "ECE";
    }
    if (lowerName.contains("civil")) return "CE";
    if (lowerName.contains("architecture")) return "B.Arch";

    // 3. Fallback: First letter of each word (max 2)
    List<String> words = name.split(" ");
    if (words.length > 1) {
      return words.take(2).map((e) => e[0].toUpperCase()).join();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgColor,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Departments',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(25), // Heavy rounding
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: textColor, fontSize: 14),
                onChanged:
                    (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search departments...",
                  hintStyle: GoogleFonts.poppins(
                    color: subtitleColor,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: subtitleColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // --- Department Grid ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('departments')
                      .orderBy('name')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF3E8E)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState(isDark, subtitleColor);
                }

                // Filter Logic
                final allDocs = snapshot.data!.docs;
                final filteredDocs =
                    allDocs.where((doc) {
                      final name = (doc['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState(isDark, subtitleColor);
                }

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95, // Matches the new visual style
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final String name = doc['name'] ?? 'Unknown';
                    final String acronym = _getAcronym(name);
                    final List<Color> gradient =
                        _gradients[index % _gradients.length];

                    return _ModernDepartmentCard(
                      name: name,
                      acronym: acronym,
                      gradient: gradient,
                      cardColor: cardColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      isDark: isDark,
                      onTap: () {
                        // Specifically check for MCA to open the detailed menu
                        if (name.toLowerCase().contains(
                              "computer application",
                            ) ||
                            name.toLowerCase().contains("mca") ||
                            acronym == "MCA") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DepartmentDetailMenuScreen(
                                    deptName: name,
                                    deptAcronym: acronym,
                                    hodUrl: "https://www.rit.ac.in/ca.php",
                                    facultyUrl:
                                        "https://www.rit.ac.in/ca-faculty.php",
                                    placementUrl:
                                        "https://www.rit.ac.in/ca.php",
                                  ),
                            ),
                          );
                        } else {
                          // Generic fallback for non-configured departments
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$name details coming soon!'),
                              backgroundColor: textColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color subtitleColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 60,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            "No departments found",
            style: GoogleFonts.poppins(color: subtitleColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// --- MODERN CARD WIDGET WITH ANIMATION ---
class _ModernDepartmentCard extends StatefulWidget {
  final String name;
  final String acronym;
  final List<Color> gradient;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernDepartmentCard({
    required this.name,
    required this.acronym,
    required this.gradient,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ModernDepartmentCard> createState() => _ModernDepartmentCardState();
}

class _ModernDepartmentCardState extends State<_ModernDepartmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(30), // Deep curves
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Vibrant Gradient Circle containing Acronym
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.last.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.acronym,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Full Department Name
                Text(
                  widget.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
