import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class AdminManageHomeBannersScreen extends StatefulWidget {
  const AdminManageHomeBannersScreen({super.key});
  @override
  State<AdminManageHomeBannersScreen> createState() =>
      _AdminManageHomeBannersScreenState();
}

class _AdminManageHomeBannersScreenState
    extends State<AdminManageHomeBannersScreen> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _linkController = TextEditingController();

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  void _showAddBannerDialog() {
    _linkController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            'Add New Banner',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter an optional link to redirect users when they tap the banner.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _linkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'https://...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _uploadNewBanner(); // Start upload process
              },
              icon: const Icon(Icons.image, color: Colors.black),
              label: const Text(
                'Pick Image & Upload',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadNewBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, folder: 'home_banners'),
      );

      await FirebaseFirestore.instance.collection('home_banners').add({
        'imageUrl': response.secureUrl,
        'linkUrl': _linkController.text.trim(), // Save the attached link
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Banner added successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteBanner(String docId) async {
    await FirebaseFirestore.instance
        .collection('home_banners')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Home Banners', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _showAddBannerDialog,
        backgroundColor: Colors.yellow,
        icon:
            _isUploading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
                : const Icon(Icons.add, color: Colors.black),
        label: Text(
          "Add Banner",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('home_banners')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            );
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No banners added yet.",
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: data['imageUrl'] ?? '',
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder:
                          (c, u) => const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    ),
                    ListTile(
                      title: Text(
                        "Banner ${index + 1}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        data['linkUrl'] != null &&
                                data['linkUrl'].toString().isNotEmpty
                            ? "Link: ${data['linkUrl']}"
                            : "No Link Attached",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _deleteBanner(doc.id),
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
