import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// --- FIX APPLIED HERE: Corrected the import path ---
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// Reuse the Cloudinary constants from your profile screen
const String cloudinaryCloudName = "dcboqibnx";
const String cloudinaryUploadPreset = "flutter_profile_uploads";

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _createPost() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image for your post.')),
      );
      return;
    }
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );

      // 1. Upload image to Cloudinary
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          _imageFile!.path,
          folder: 'posts/${user.uid}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final imageUrl = response.secureUrl;

      // 2. Fetch user's profile data to include in the post
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // 3. Create post data map
      final postData = {
        'postImageUrl': imageUrl,
        'caption': _captionController.text,
        'userId': user.uid,
        'userName': userData['displayName'] ?? 'A User',
        'userImageUrl':
            userData['profilePhotoUrl'] ?? '', // Use a default if not set
        'timestamp': FieldValue.serverTimestamp(), // For sorting
        'likes': 0,
        'comments': 0,
      };

      // 4. Save to Firestore
      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (!mounted) return;
      // Pop screen and return `true` to signal a refresh
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Create New Post',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Disable button while uploading
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createPost,
              child: Text(
                'Post',
                style: GoogleFonts.poppins(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 1, // Square aspect ratio
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    image:
                        _imageFile != null
                            ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                            : null,
                  ),

                  child:
                      _imageFile == null
                          ? const Center(
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              size: 60,
                              color: Colors.white70,
                            ),
                          )
                          : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: const TextStyle(color: Colors.white70),
                fillColor: Colors.grey.shade900,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
