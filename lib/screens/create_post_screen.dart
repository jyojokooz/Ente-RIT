import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart'; // <-- 1. IMPORT
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // <-- For creating a temp path

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

  // --- 2. ADD THE COMPRESSION HELPER FUNCTION ---
  Future<File?> _compressImage(File file) async {
    // Get a temporary directory to store the compressed file.
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Compress the file
    final XFile? compressedXFile =
        await FlutterImageCompress.compressAndGetFile(
          file.absolute.path, // The path of the original file
          tempPath, // The path to save the compressed file
          quality: 70, // Compression quality (0-100)
          minWidth: 1080, // Resize the image if it's wider than this
          minHeight: 1080, // Resize the image if it's taller than this
        );

    if (compressedXFile == null) return null;
    return File(compressedXFile.path);
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image.')));
      return;
    }
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      // --- 3. COMPRESS THE IMAGE BEFORE UPLOADING ---
      final compressedFile = await _compressImage(_imageFile!);
      if (compressedFile == null) {
        throw Exception('Image compression failed.');
      }

      final user = FirebaseAuth.instance.currentUser!;
      final cloudinary = CloudinaryPublic(
        cloudinaryCloudName,
        cloudinaryUploadPreset,
      );

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          compressedFile.path, // <-- Use the compressed file
          folder: 'posts/${user.uid}',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // ... rest of the function is the same ...
      final imageUrl = response.secureUrl;
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final userData = userDoc.data() as Map<String, dynamic>;
      final postData = {
        'postImageUrl': imageUrl,
        'caption': _captionController.text,
        'userId': user.uid,
        'userName': userData['displayName'] ?? 'A User',
        'username': userData['username'] ?? '',
        'userImageUrl': userData['profilePhotoUrl'] ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
        'comments': 0,
      };
      await FirebaseFirestore.instance.collection('posts').add(postData);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create post: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ... rest of the file (dispose, build) is unchanged ...
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
                aspectRatio: 1,
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
