import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Campus Events', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .where('eventDate', isGreaterThanOrEqualTo: Timestamp.now())
            .orderBy('eventDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.yellow));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No upcoming events.', style: GoogleFonts.poppins(color: Colors.white70)));
          }
          final events = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final eventData = events[index].data() as Map<String, dynamic>;
              final eventDate = (eventData['eventDate'] as Timestamp).toDate();
              final imageUrl = eventData['imageUrl'] as String?;
              
              return Card(
                color: Colors.grey.shade900,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias, // Important for the image border radius
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- THE EVENT BANNER IMAGE ---
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const SizedBox(height: 180, child: Icon(Icons.image_not_supported)),
                      ),
                      
                    // --- EVENT DETAILS ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE, MMM d • h:mm a').format(eventDate),
                            style: GoogleFonts.poppins(color: Colors.yellow, fontWeight: FontWeight.w600, fontSize: 14)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            eventData['title'] ?? 'Event', 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            eventData['description'] ?? '', 
                            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5)
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}