// ===============================
// FILE NAME: department_detail_menu_screen.dart
// FILE PATH: lib/screens/department_detail_menu_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'department_sub_screens.dart';
import 'department_notes_screen.dart';

class DepartmentDetailMenuScreen extends StatelessWidget {
  final String deptName;
  final String deptAcronym; // e.g., 'MCA'

  // URLs for scraping (passed from previous screen)
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          deptAcronym,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deptName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Department Information Center",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _MenuCard(
                    title: "HOD's Desk",
                    icon: Icons.admin_panel_settings_rounded,
                    color: Colors.blueAccent,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HodInfoScreen(url: hodUrl),
                          ),
                        ),
                  ),
                  _MenuCard(
                    title: "Faculty",
                    icon: Icons.groups_rounded,
                    color: Colors.orangeAccent,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FacultyListScreen(url: facultyUrl),
                          ),
                        ),
                  ),
                  _MenuCard(
                    title: "Placements",
                    icon: Icons.work_rounded,
                    color: Colors.green,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PlacementInfoScreen(url: placementUrl),
                          ),
                        ),
                  ),
                  _MenuCard(
                    title: "Notes & Materials",
                    icon: Icons.library_books_rounded,
                    color: Colors.purpleAccent,
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

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 10),
                ],
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
