import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
  final _priceController = TextEditingController();
  final MarketplaceService _marketplaceService = MarketplaceService();
  final _currentUser = FirebaseAuth.instance.currentUser!;

  File? _imageFile;
  bool _isSubmitting = false;
  String? _selectedCategory;

  String? _userName;
  String? _userProfilePhotoUrl;
  bool _isLoadingProfile = true;

  final List<String> _categories = [
    'Textbooks',
    'Electronics',
    'Lab & Gear',
    'Dorm Supplies',
    'Gaming',
    'Tutoring & Skills',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUser.uid)
              .get();
      if (mounted && userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'];
          _userProfilePhotoUrl = userDoc.data()?['profilePhotoUrl'];
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('marketplace_images')
          .child(fileName);
      await ref.putFile(image);
      return await ref.getDownloadURL();
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
      setState(() => _isSubmitting = true);

      final imageUrl = await _uploadImageToFirebase(_imageFile!);
      if (imageUrl == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final productData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'imageUrl': imageUrl,
        'sellerId': _currentUser.uid,
        'sellerName': _userName ?? _currentUser.displayName ?? 'Anonymous',
        'sellerPhotoUrl': _userProfilePhotoUrl ?? _currentUser.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'category': _selectedCategory,
      };

      await _marketplaceService.addProduct(productData);

      if (mounted) {
        setState(() => _isSubmitting = false);
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
      body:
          _isLoadingProfile
              ? const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              )
              : Stack(
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_a_photo_outlined,
                                            size: 50,
                                            color: Colors.white70,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            "Tap to select an image",
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,

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
                            onChanged:
                                (newValue) => setState(
                                  () => _selectedCategory = newValue,
                                ),
                            validator:
                                (value) =>
                                    value == null
                                        ? 'Please select a category'
                                        : null,
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
                              labelText: 'Price (₹)',
                              border: OutlineInputBorder(),
                              prefixText: '₹',
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
                            onPressed: _isSubmitting ? null : _submitListing,
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
                  if (_isSubmitting)
                    Container(
                      color: const Color.fromRGBO(0, 0, 0, 0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.amber),
                            SizedBox(height: 16),
                            Text(
                              "Uploading...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
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
