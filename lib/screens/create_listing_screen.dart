import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/marketplace_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});
  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  // --- FIX: Corrected the typo on this line ---
  final _priceController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  File? _imageFile;
  bool _isLoading = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Textbooks',
    'Electronics',
    'Lab & Gear',
    'Dorm Supplies',
    'Gaming',
    'Tutoring & Skills',
    'Other',
  ];

  final String _cloudinaryCloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _cloudinaryUploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File image) async {
    if (_cloudinaryCloudName.isEmpty || _cloudinaryUploadPreset.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cloudinary credentials are not set.")),
        );
      }
      return null;
    }
    final cloudinary = CloudinaryPublic(
      _cloudinaryCloudName,
      _cloudinaryUploadPreset,
      cache: false,
    );
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response.secureUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
      }
      return null;
    }
  }

  Future<void> _submitListing() async {
    if (_formKey.currentState!.validate() &&
        _imageFile != null &&
        _selectedCategory != null) {
      setState(() {
        _isLoading = true;
      });

      final imageUrl = await _uploadImageToCloudinary(_imageFile!);
      if (imageUrl == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'sellerId': _currentUser.uid,
        'sellerName': _currentUser.displayName ?? 'Anonymous',
        'sellerPhotoUrl': _currentUser.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'category': _selectedCategory,
      };

      await _marketplaceService.addProduct(productData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing posted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields, select a category, and add an image.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Create New Listing",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.grey.shade900,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child:
                          _imageFile != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 50,
                                    color: Colors.white70,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Tap to select an image",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white70,
                    dropdownColor: Colors.grey.shade800,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                    validator:
                        (value) =>
                            value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        (value) =>
                            value!.trim().isEmpty
                                ? 'Title cannot be empty'
                                : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _priceController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Price (\$)',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Price cannot be empty';
                      }
                      if (double.tryParse(value.trim()) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    validator:
                        (value) =>
                            value!.trim().isEmpty
                                ? 'Description cannot be empty'
                                : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitListing,
                    icon: const Icon(Icons.publish),
                    label: const Text('Post Listing'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.black,
                      textStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      "Uploading...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
