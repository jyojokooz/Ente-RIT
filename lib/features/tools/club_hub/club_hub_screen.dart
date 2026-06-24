// ===============================
// FILE NAME: club_hub_screen.dart
// FILE PATH: lib/features/tools/club_hub/club_hub_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ClubHubScreen extends StatefulWidget {
  const ClubHubScreen({super.key});

  @override
  State<ClubHubScreen> createState() => _ClubHubScreenState();
}

class _ClubHubScreenState extends State<ClubHubScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
          'Club Hub',
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
                hintText: 'Search clubs...',
                hintStyle: GoogleFonts.poppins(
                  color: subtitleColor,
                ),
                filled: true,
                fillColor: cardColor,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFAB47BC),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          // --- Clubs List ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clubs')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFAB47BC)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.diversity_3_outlined,
                          size: 64,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No clubs found',
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
                  return name.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No matching clubs found',
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
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final logoUrl = data['logoUrl'] as String?;
                    final members = List<String>.from(data['members'] ?? []);
                    final isMember = FirebaseAuth.instance.currentUser != null &&
                        members.contains(FirebaseAuth.instance.currentUser!.uid);

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
                          // Club Logo
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFAB47BC).withOpacity(0.1),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: logoUrl != null && logoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: logoUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(
                                      Icons.groups_rounded,
                                      color: Color(0xFFAB47BC),
                                      size: 32,
                                    ),
                                  )
                                : const Icon(
                                    Icons.groups_rounded,
                                    color: Color(0xFFAB47BC),
                                    size: 32,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['name'] ?? 'Unknown Club',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['description'] ?? 'No description',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: subtitleColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${members.length} members',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFAB47BC),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Join / Leave Button
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid == null) return;
                              if (isMember) {
                                members.remove(uid);
                              } else {
                                members.add(uid);
                              }
                              await doc.reference.update({'members': members});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isMember
                                  ? Colors.transparent
                                  : const Color(0xFFAB47BC),
                              foregroundColor: isMember
                                  ? const Color(0xFFAB47BC)
                                  : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isMember
                                    ? const BorderSide(color: Color(0xFFAB47BC))
                                    : BorderSide.none,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                            child: Text(
                              isMember ? 'Joined' : 'Join',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
