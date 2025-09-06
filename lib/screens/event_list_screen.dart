import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// A simple model class to represent an event.
class Event {
  final String title;
  final String description;
  final DateTime date;
  final String? imageUrl;

  Event({
    required this.title,
    required this.description,
    required this.date,
    this.imageUrl,
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Campus Events',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
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
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Something went wrong.',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No upcoming events.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

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
            );

            if (_events[eventDay] == null) {
              _events[eventDay] = [];
            }
            _events[eventDay]!.add(event);
          }

          _selectedEvents = _getEventsForDay(_selectedDay);

          return Column(
            children: [
              _buildTableCalendar(),
              const SizedBox(height: 8.0),
              Expanded(child: _buildEventList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTableCalendar() {
    return TableCalendar<Event>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.month,
      eventLoader: _getEventsForDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16.0,
        ),
        leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: GoogleFonts.poppins(color: Colors.white70),
        weekendTextStyle: GoogleFonts.poppins(color: Colors.white),
        todayDecoration: BoxDecoration(
          // --- FIX APPLIED HERE ---
          // Replaced deprecated withOpacity(0.3) with withAlpha(77).
          color: Colors.yellow.withAlpha(77),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: GoogleFonts.poppins(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        markerDecoration: const BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents.isEmpty) {
      return Center(
        child: Text(
          "No events for this day.",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];

        return Card(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.imageUrl != null)
                Image.network(
                  event.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const SizedBox(
                        height: 180,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.white30,
                        ),
                      ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d • h:mm a').format(event.date),
                      style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
