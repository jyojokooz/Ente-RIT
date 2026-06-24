// ===============================
// FILE NAME: alumni_connect_screen.dart
// FILE PATH: lib/features/tools/alumni_connect/alumni_connect_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AlumniConnectScreen extends StatefulWidget {
  const AlumniConnectScreen({super.key});

  @override
  State<AlumniConnectScreen> createState() => _AlumniConnectScreenState();
}

class _AlumniConnectScreenState extends State<AlumniConnectScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedDept = 'All';

  final List<String> _departments = [
    'All',
    'CSE',
    'ECE',
    'ME',
    'CE',
    'EEE',
    'MCA',
  ];

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Alumni Connect',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Search alumni by name or company...',
                hintStyle: GoogleFonts.poppins(
                  color: subtitleColor,
                ),
                filled: true,
                fillColor: cardColor,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF4ECDC4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // --- Department Filter ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final dept = _departments[index];
                final isSelected = _selectedDept == dept;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDept = dept),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4ECDC4) : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: isDark && !isSelected
                          ? Border.all(color: Colors.white10)
                          : null,
                    ),
                    child: Text(
                      dept,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isSelected ? Colors.white : subtitleColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- Alumni List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alumni')
                  .orderBy('batch', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4ECDC4)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 64,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No alumni profiles found',
                          style: GoogleFonts.poppins(
                            color: subtitleColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final company = (data['company'] ?? '').toString().toLowerCase();
                  final dept = data['department'] ?? '';

                  final matchesSearch = name.contains(_searchQuery) ||
                      company.contains(_searchQuery);
                  final matchesDept = _selectedDept == 'All' || dept == _selectedDept;

                  return matchesSearch && matchesDept;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching alumni found',
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontSize: 15,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final profileUrl = data['profileUrl'] as String?;
                    final linkedin = data['linkedinUrl'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: isDark
                            ? Border.all(color: Colors.white.withOpacity(0.05))
                            : null,
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Profile Image
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4ECDC4).withOpacity(0.1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: profileUrl != null && profileUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: profileUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(
                                      Icons.person_rounded,
                                      color: Color(0xFF4ECDC4),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF4ECDC4),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${data['designation'] ?? 'Alumnus'} @ ${data['company'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF4ECDC4),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white10
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Batch: ${data['batch'] ?? 'N/A'}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      data['department'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // LinkedIn Button
                          if (linkedin != null && linkedin.isNotEmpty)
                            IconButton(
                              onPressed: () => _launchUrl(linkedin),
                              icon: const Icon(
                                Icons.link_rounded,
                                color: Color(0xFF4ECDC4),
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF4ECDC4).withOpacity(0.1),
                              ),
                            ),
                        ],
                      ),
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
}
