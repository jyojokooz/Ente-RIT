// ===============================
// FILE NAME: home_campus_highlights.dart
// FILE PATH: lib/widgets/home/home_campus_highlights.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../screens/event_list_screen.dart';

class HomeCampusHighlights extends StatelessWidget {
  final bool isDark;

  const HomeCampusHighlights({super.key, required this.isDark});

  // Helper function to format the date exactly like the design
  Map<String, dynamic> _formatEventTime(DateTime eventDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

    // If the event is today and the current time is around the event time (e.g., within 4 hours)
    if (eventDay == today &&
        now.isAfter(eventDate.subtract(const Duration(hours: 1))) &&
        now.isBefore(eventDate.add(const Duration(hours: 4)))) {
      return {'text': 'Live Now', 'isLive': true};
    } else if (eventDay == today) {
      return {
        'text': 'Today, ${DateFormat('h a').format(eventDate)}',
        'isLive': false,
      };
    } else if (eventDay == tomorrow) {
      return {
        'text': 'Tomorrow, ${DateFormat('h a').format(eventDate)}',
        'isLive': false,
      };
    } else {
      return {
        'text': DateFormat('dd MMM • h a').format(eventDate),
        'isLive': false,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ROW ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'CAMPUS HIGHLIGHTS',
                style: GoogleFonts.permanentMarker(
                  // Brush script style font
                  fontSize: 16, // Slightly smaller header
                  color: textColor,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventListScreen()),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9983F3), // Purple accent
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9983F3),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- HORIZONTAL LIST ---
        SizedBox(
          height: 160, // REDUCED HEIGHT: Changed from 220 to 160
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('events')
                    .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
                    .orderBy('eventDate')
                    .limit(5) // Get top 5 upcoming events
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9983F3)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No upcoming highlights.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              final events = snapshot.data!.docs;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final eventData =
                      events[index].data() as Map<String, dynamic>;
                  final title = eventData['title'] ?? 'Event';
                  final imageUrl = eventData['imageUrl'] ?? '';
                  final date = (eventData['eventDate'] as Timestamp).toDate();

                  final timeInfo = _formatEventTime(date);
                  final isLive = timeInfo['isLive'] as bool;
                  final timeText = timeInfo['text'] as String;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EventListScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 120, // REDUCED WIDTH: Changed from 150 to 120
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF252528)
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(
                          14,
                        ), // Slightly softer corners for smaller size
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 1. Background Image
                            if (imageUrl.isNotEmpty)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder:
                                    (context, url) =>
                                        Container(color: Colors.black12),
                                errorWidget:
                                    (context, url, error) => const Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                    ),
                              )
                            else
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF3B2667),
                                      Color(0xFFBC78EC),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),

                            // 2. Dark Gradient Overlay for Text Readability
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.9),
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.45, 0.8],
                                  ),
                                ),
                              ),
                            ),

                            // 3. LIVE Badge (Top Left)
                            if (isLive)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF3E8E,
                                    ), // Pinkish Red
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "LIVE",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 8, // Smaller font
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),

                            // 4. Content (Bottom)
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 8,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Text Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          title,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11, // Smaller title
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            if (isLive) ...[
                                              Container(
                                                width: 5,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFFF3E8E),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            Expanded(
                                              child: Text(
                                                timeText,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white70,
                                                  fontSize:
                                                      9, // Smaller time text
                                                  fontWeight: FontWeight.w500,
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
                                  // Arrow Button
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 12, // Smaller icon
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
