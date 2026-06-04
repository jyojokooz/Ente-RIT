// ===============================
// FILE NAME: faculty_list_screen.dart
// FILE PATH: lib/features/campus/presentation/department_sub_screens/faculty_list_screen.dart
// ===============================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/campus/data/rit_scraper_service.dart';
import 'package:my_project/features/campus/presentation/department_sub_screens/department_connector.dart';

class FacultyListScreen extends StatelessWidget {
  final String url;
  const FacultyListScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    final RitScraperService scraper = RitScraperService();
    const int mcaDepartmentId = 8;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          "Staff Members",
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
      body: FutureBuilder<List<FacultyModel>>(
        future: scraper.fetchFacultyFromApi(mcaDepartmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9A44)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No staff found.",
                style: GoogleFonts.poppins(color: textColor),
              ),
            );
          }

          final allStaff = snapshot.data!;
          final faculty = allStaff.where((s) => s.type == 'Faculty').toList();
          final techStaff =
              allStaff.where((s) => s.type == 'Technical Staff').toList();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (faculty.isNotEmpty) ...[
                  _SectionHeader(
                    title: "Faculty",
                    color: const Color(0xFFFF9A44),
                    isDark: isDark,
                    textColor: textColor,
                  ),
                  _StaffGrid(
                    staffList: faculty,
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                ],
                if (techStaff.isNotEmpty) ...[
                  _SectionHeader(
                    title: "Technical Staff",
                    color: const Color(0xFF43E97B),
                    isDark: isDark,
                    textColor: textColor,
                  ),
                  _StaffGrid(
                    staffList: techStaff,
                    cardColor: cardColor,
                    textColor: textColor,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final bool isDark;
  final Color textColor;
  const _SectionHeader({
    required this.title,
    required this.color,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffGrid extends StatelessWidget {
  final List<FacultyModel> staffList;
  final Color cardColor;
  final Color textColor;
  final bool isDark;

  const _StaffGrid({
    required this.staffList,
    required this.cardColor,
    required this.textColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: staffList.length,
      itemBuilder: (context, index) {
        final staff = staffList[index];
        return GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffProfileScreen(staffId: staff.id),
                ),
              ),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'staff_list_${staff.id}',
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      backgroundImage: CachedNetworkImageProvider(
                        staff.imageUrl,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    staff.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    staff.designation,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
