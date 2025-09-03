import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// This list MUST match the IDs used in your ClassifyScreen.
// It is the source of truth for this admin screen.
const List<Map<String, String>> featureList = [
  {'id': 'department_notes', 'label': 'Department Notes'},
  {'id': 'events', 'label': 'Events'},
  {'id': 'tech_news', 'label': 'Tech News'},
  {'id': 'games', 'label': 'Games'},
  {'id': 'digital_id', 'label': 'Digital ID'},
  {'id': 'connect_ai', 'label': 'Connect AI'},
  {'id': 'code_playground', 'label': 'Code Playground'},
  {'id': 'dev_community', 'label': 'Dev Community'},
  {'id': 'etlab', 'label': 'RIT ETLab'},
  {'id': 'lost_and_found', 'label': 'Lost & Found'},
  {'id': 'peer_rooms', 'label': 'Peer Rooms'},
  {'id': 'marketplace', 'label': 'Marketplace'},
  {'id': 'quiz', 'label': 'Programming Quiz'},
  {'id': 'pdf_buddy', 'label': 'PDF Study Buddy'},
  {'id': 'linkedin_analyzer', 'label': 'LinkedIn Analyzer'},
  {'id': 'youtube_summarizer', 'label': 'YouTube Summarizer'},
  {'id': 'nonote', 'label': 'No-Note'},
];

class AdminManageCardImagesScreen extends StatefulWidget {
  const AdminManageCardImagesScreen({super.key});

  @override
  State<AdminManageCardImagesScreen> createState() =>
      _AdminManageCardImagesScreenState();
}

class _AdminManageCardImagesScreenState
    extends State<AdminManageCardImagesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize a controller for each feature defined in the list.
    _controllers = {
      for (var feature in featureList) feature['id']!: TextEditingController(),
    };
    _loadInitialData();
  }

  // Fetches the current image URLs from Firestore and populates the text fields.
  Future<void> _loadInitialData() async {
    try {
      for (var feature in featureList) {
        final docId = feature['id']!;
        final doc =
            await _firestore.collection('card_backgrounds').doc(docId).get();
        if (doc.exists && doc.data()!.containsKey('imageUrl')) {
          _controllers[docId]?.text = doc.data()!['imageUrl'];
        }
      }
    } catch (e) {
      // Handle potential errors during fetching, e.g., network issues.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      // Ensure the loading indicator is hidden even if an error occurs.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Saves all the URLs from the text fields back to Firestore using a batch write.
  Future<void> _saveAllImages() async {
    final snackBar = ScaffoldMessenger.of(context);
    snackBar.showSnackBar(
      const SnackBar(content: Text('Saving all image URLs...')),
    );

    try {
      final batch = _firestore.batch();
      _controllers.forEach((docId, controller) {
        final docRef = _firestore.collection('card_backgrounds').doc(docId);
        // 'set' will create the document if it doesn't exist or overwrite it if it does.
        batch.set(docRef, {'imageUrl': controller.text.trim()});
      });

      await batch.commit();

      snackBar.showSnackBar(
        const SnackBar(
          content: Text('Successfully saved!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      snackBar.showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Clean up the controllers when the widget is removed from the widget tree.
  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Manage Card Images',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed:
                _isLoading ? null : _saveAllImages, // Disable while loading
            tooltip: 'Save All',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: featureList.length,
                itemBuilder: (context, index) {
                  final feature = featureList[index];
                  final featureId = feature['id']!;
                  final featureLabel = feature['label']!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      controller: _controllers[featureId],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: featureLabel,
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Paste image URL here',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.yellow.shade700),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
