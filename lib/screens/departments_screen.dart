// ===============================
// FILE NAME: departments_screen.dart
// FILE PATH: lib/screens/departments_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'department_detail_menu_screen.dart'; // Make sure this import is correct

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // A list of modern gradients to cycle through
  final List<List<Color>> _gradients = [
    [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
    [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
    [const Color(0xFFfa709a), const Color(0xFFfee140)], // Pink/Yellow
    [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
    [const Color(0xFFff9a9e), const Color(0xFFfecfef)], // Pastel Pink
    [const Color(0xFFa18cd1), const Color(0xFFfbc2eb)], // Lavender
    [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Red/Pink
    [const Color(0xFF89f7fe), const Color(0xFF66a6ff)], // Sky Blue
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper to generate an acronym (e.g., Computer Science -> CSE)
  String _getAcronym(String name) {
    if (name.isEmpty) return "";

    // Manual overrides for standard engineering acronyms
    String lowerName = name.toLowerCase();
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
    if (lowerName.contains("application")) return "MCA";

    // Fallback: First letter of each word
    List<String> words = name.split(" ");
    if (words.length > 1) {
      return words.take(2).map((e) => e[0].toUpperCase()).join();
    }
    return name.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Departments',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.poppins(color: Colors.black),
                onChanged:
                    (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: "Search departments...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
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
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                // Filter Logic based on search query
                final allDocs = snapshot.data!.docs;
                final filteredDocs =
                    allDocs.where((doc) {
                      final name = (doc['name'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery);
                    }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Columns
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85, // Taller cards
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final String name = doc['name'] ?? 'Unknown';
                    final String acronym = _getAcronym(name);
                    final List<Color> gradient =
                        _gradients[index % _gradients.length];

                    return _buildModernCard(name, acronym, gradient, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCard(
    String name,
    String acronym,
    List<Color> gradient,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        // --- NAVIGATION LOGIC ---
        // Specifically check for MCA or Computer Applications to open the detailed menu
        if (name.toLowerCase().contains("computer applications") ||
            name.toLowerCase().contains("mca") ||
            acronym == "MCA") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => DepartmentDetailMenuScreen(
                    deptName: name, // Pass the actual name
                    deptAcronym: acronym,
                    // Passing the specific RIT URLs for scraping
                    hodUrl: "https://www.rit.ac.in/ca.php",
                    facultyUrl: "https://www.rit.ac.in/ca-faculty.php",
                    placementUrl: "https://www.rit.ac.in/ca.php",
                  ),
            ),
          );
        } else {
          // Fallback for other departments (can be expanded later)
          // For now, we will just direct them to the same menu but with a generic placeholder or the same RIT URLs if the pattern matches
          // Or show a "Coming Soon" if URLs are unique per dept and not yet known.

          // Let's assume we want to enable this feature for all departments,
          // but we might not have the correct URLs for others yet.
          // For safety, we show a snackbar for non-MCA departments.

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name details coming soon!'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Big Icon in Background
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.school,
                size: 100,
                color: Colors.white.withOpacity(0.15),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon Top Right
                  const Align(
                    alignment: Alignment.topRight,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.arrow_outward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  // Text Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acronym,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No departments found",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
