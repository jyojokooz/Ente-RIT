// ===============================
// FILE NAME: lost_found_item_card.dart
// FILE PATH: lib/widgets/lost_found_item_card.dart
// ===============================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LostFoundItemCard extends StatelessWidget {
  final String title;
  final String status;
  final String location;
  final String userName;
  final String? imageUrl;
  final bool isResolved;
  final bool isOwner;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LostFoundItemCard({
    super.key,
    required this.title,
    required this.status,
    required this.location,
    required this.userName,
    this.imageUrl,
    this.isResolved = false,
    this.isOwner = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    // Status Colors
    final isLost = status.toLowerCase() == 'lost';
    final statusColors =
        isResolved
            ? const [Color(0xFF43E97B), Color(0xFF38F9D7)] // Green
            : isLost
            ? const [Color(0xFFFF9A44), Color(0xFFFF3E8E)] // Orange/Pink
            : const [Color(0xFF00C6FB), Color(0xFF005BEA)]; // Blue

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE SECTION ---
              SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder:
                            (c, u) => Container(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                        errorWidget: (c, u, e) => _buildFallbackGradient(),
                      )
                    else
                      _buildFallbackGradient(),

                    // Gradient Overlay for Text/Badges
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              cardColor,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Top Left Status Badge
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: statusColors),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: statusColors.last.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          isResolved ? "RESOLVED" : status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    // Top Right Owner Actions
                    if (isOwner && !isResolved)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') onEdit();
                                  if (value == 'delete') onDelete();
                                },
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                color:
                                    isDark
                                        ? Colors.grey.shade900
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                itemBuilder:
                                    (ctx) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              color: textColor,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: textColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // --- TEXT CONTENT ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: statusColors.first,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: subtitleColor,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Reported by $userName",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: subtitleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.find_in_page_rounded,
          color: Colors.white24,
          size: 60,
        ),
      ),
    );
  }
}
