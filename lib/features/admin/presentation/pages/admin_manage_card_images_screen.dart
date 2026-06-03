// lib/screens/admin/admin_manage_card_images_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_project/features/admin/data/image_upload_service.dart';

// This list MUST match the IDs used in your ClassifyScreen.
// REPLACE the old featureList at the top of the file with this:

const List<Map<String, String>> featureList = [
  {'id': 'department_notes', 'label': 'Department Notes'},
  {'id': 'events', 'label': 'Events'},
  {'id': 'lost_and_found', 'label': 'Lost & Found'},
  {'id': 'marketplace', 'label': 'Marketplace'},
  {'id': 'cafeteria', 'label': 'Cafeteria'},
  {'id': 'bus_tracker', 'label': 'Bus Tracker'},
  {'id': 'peer_rooms', 'label': 'Peer Rooms'},
  {'id': 'nonote', 'label': 'No-Note'},
  {'id': 'digital_id', 'label': 'Digital ID'},
  {'id': 'code_playground', 'label': 'Code Playground'},
  {'id': 'dev_community', 'label': 'Stack Overflow'},
  {'id': 'games', 'label': 'Games'},
  {'id': 'etlab', 'label': 'RIT ETLab'},
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
  final ImageUploadService _imageUploadService = ImageUploadService();
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var feature in featureList) feature['id']!: TextEditingController(),
    };
    _loadInitialData();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadImageForFeature(String featureId) async {
    final snackBar = ScaffoldMessenger.of(context);

    // 1. Pick Image
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null || result.files.single.path == null) {
      snackBar.showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
      return;
    }

    File imageFile = File(result.files.single.path!);
    snackBar.showSnackBar(const SnackBar(content: Text('Uploading image...')));

    // 2. Upload to Cloudinary
    try {
      final newUrl = await _imageUploadService.uploadImage(imageFile);
      // 3. Update Controller and UI
      setState(() {
        _controllers[featureId]?.text = newUrl;
      });
      snackBar.showSnackBar(
        const SnackBar(
          content: Text('Upload successful! Remember to save.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      snackBar.showSnackBar(
        SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAllImages() async {
    final snackBar = ScaffoldMessenger.of(context);
    snackBar.showSnackBar(
      const SnackBar(content: Text('Saving all image URLs...')),
    );
    try {
      final batch = _firestore.batch();
      _controllers.forEach((docId, controller) {
        final docRef = _firestore.collection('card_backgrounds').doc(docId);
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
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAllImages,
            tooltip: 'Save All Changes',
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
                  final controller = _controllers[featureId]!;

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.only(bottom: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            featureLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // AnimatedBuilder rebuilds the image whenever the controller's text changes.
                        AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            return CachedNetworkImage(
                              imageUrl: controller.text,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    height: 150,
                                    color: Colors.grey.shade800,
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          color: Colors.white54,
                                          size: 40,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'No Image or Invalid URL',
                                          style: TextStyle(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            );
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: controller,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Image URL',
                                  labelStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade800,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      () => _uploadImageForFeature(featureId),
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Upload New Image'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.yellow,
                                    foregroundColor: Colors.black,
                                    textStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
