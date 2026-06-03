// ===============================
// FILE NAME: department_detail_menu_screen.dart
// FILE PATH: lib/screens/department_detail_menu_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project/features/campus/presentation/department_sub_screens.dart';
import 'package:my_project/features/campus/presentation/department_notes_screen.dart';

class DepartmentDetailMenuScreen extends StatelessWidget {
  final String deptName;
  final String deptAcronym;

  final String hodUrl;
  final String facultyUrl;
  final String placementUrl;

  const DepartmentDetailMenuScreen({
    super.key,
    required this.deptName,
    required this.deptAcronym,
    required this.hodUrl,
    required this.facultyUrl,
    required this.placementUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          deptAcronym,
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deptName,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Department Information Center",
              style: GoogleFonts.poppins(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 32),

            Expanded(
              child: GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _ModernMenuCard(
                    title: "HOD's Desk",
                    icon: Icons.admin_panel_settings_rounded,
                    color: const Color(0xFF00C6FB), // Vibrant Blue
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HodInfoScreen(url: hodUrl),
                          ),
                        ),
                  ),
                  _ModernMenuCard(
                    title: "Faculty",
                    icon: Icons.groups_rounded,
                    color: const Color(0xFFFF9A44), // Vibrant Orange
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FacultyListScreen(url: facultyUrl),
                          ),
                        ),
                  ),
                  _ModernMenuCard(
                    title: "Placements",
                    icon: Icons.work_rounded,
                    color: const Color(0xFF43E97B), // Vibrant Green
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PlacementInfoScreen(url: placementUrl),
                          ),
                        ),
                  ),
                  _ModernMenuCard(
                    title: "Notes & Materials",
                    icon: Icons.library_books_rounded,
                    color: const Color(0xFFB165FF), // Vibrant Purple
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => DepartmentNotesScreen(
                                  departmentId: deptAcronym,
                                ),
                          ),
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

class _ModernMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_ModernMenuCard> createState() => _ModernMenuCardState();
}

class _ModernMenuCardState extends State<_ModernMenuCard>
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
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 30),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
