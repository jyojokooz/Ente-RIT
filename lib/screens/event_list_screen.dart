// ===============================
// FILE NAME: event_list_screen.dart
// FILE PATH: lib/screens/event_list_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart'; // REQUIRED

// --- Event Model ---
class Event {
  final String title;
  final String description;
  final DateTime date;
  final String? imageUrl;
  final String? whatsappLink; // New
  final String? bookingLink; // New

  Event({
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl,
    this.whatsappLink,
    this.bookingLink,
  });
}

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  Map<DateTime, List<Event>> _events = {};
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Event> _selectedEvents = [];
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  List<Event> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _events[dayUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Campus Events',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('events')
                .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
                .orderBy('eventDate')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasData) {
            _events = {};
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final eventDate = (data['eventDate'] as Timestamp).toDate();
              final eventDay = DateTime.utc(
                eventDate.year,
                eventDate.month,
                eventDate.day,
              );

              final event = Event(
                title: data['title'] ?? 'No Title',
                description: data['description'] ?? '',
                date: eventDate,
                imageUrl: data['imageUrl'],
                whatsappLink: data['whatsappLink'], // Map New Field
                bookingLink: data['bookingLink'], // Map New Field
              );

              if (_events[eventDay] == null) _events[eventDay] = [];
              _events[eventDay]!.add(event);
            }
            _selectedEvents = _getEventsForDay(_selectedDay);
          }

          return Column(
            children: [
              _buildModernCalendar(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Text(
                      "Upcoming",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "${_selectedEvents.length}",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(child: _buildEventList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernCalendar() {
    // ... (Keep existing calendar code exactly as is)
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: TableCalendar<Event>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 17.0,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: Colors.black,
          ),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: GoogleFonts.poppins(color: Colors.black87),
          weekendTextStyle: GoogleFonts.poppins(color: Colors.redAccent),
          outsideTextStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
          todayDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.yellow.shade700, width: 2),
          ),
          todayTextStyle: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.yellow,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No events on this day",
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: _selectedEvents.length,
      separatorBuilder: (context, index) => const SizedBox(height: 24),
      itemBuilder:
          (context, index) => _ModernEventCard(event: _selectedEvents[index]),
    );
  }
}

class _ModernEventCard extends StatelessWidget {
  final Event event;
  const _ModernEventCard({required this.event});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          // Changed to Column to hold image + buttons
          children: [
            // 1. The Image Poster Section
            SizedBox(
              height: 240,
              child: Stack(
                children: [
                  Positioned.fill(
                    child:
                        event.imageUrl != null && event.imageUrl!.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: event.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) =>
                                      Container(color: Colors.grey.shade200),
                              errorWidget:
                                  (context, url, error) =>
                                      _buildFallbackGradient(),
                            )
                            : _buildFallbackGradient(),
                  ),

                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.5, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.95),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Date Badge
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('MMM').format(event.date).toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            DateFormat('dd').format(event.date),
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Text Content
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('h:mm a').format(event.date),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Action Buttons Section (New)
            if ((event.whatsappLink != null &&
                    event.whatsappLink!.isNotEmpty) ||
                (event.bookingLink != null && event.bookingLink!.isNotEmpty))
              Container(
                color: Colors.black, // Dark strip at bottom to match image fade
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    if (event.whatsappLink != null &&
                        event.whatsappLink!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL(event.whatsappLink!),
                          icon: const Icon(Icons.chat_bubble, size: 18),
                          label: const Text("Join Group"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                    if (event.whatsappLink != null && event.bookingLink != null)
                      const SizedBox(width: 12),

                    if (event.bookingLink != null &&
                        event.bookingLink!.isNotEmpty)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchURL(event.bookingLink!),
                          icon: const Icon(Icons.confirmation_number, size: 18),
                          label: const Text("Book Now"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

  Widget _buildFallbackGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.event,
          color: Colors.white.withOpacity(0.1),
          size: 80,
        ),
      ),
    );
  }
}
