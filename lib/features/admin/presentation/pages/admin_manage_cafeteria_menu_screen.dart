// ===============================
// FILE NAME: admin_manage_cafeteria_menu_screen.dart
// FILE PATH: lib/screens/admin/admin_manage_cafeteria_menu_screen.dart
// ===============================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_project/features/cafeteria/data/cloudinary_service.dart';

class AdminManageCafeteriaMenuScreen extends StatefulWidget {
  const AdminManageCafeteriaMenuScreen({super.key});

  @override
  State<AdminManageCafeteriaMenuScreen> createState() =>
      _AdminManageCafeteriaMenuScreenState();
}

class _AdminManageCafeteriaMenuScreenState
    extends State<AdminManageCafeteriaMenuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showMenuSheet(
    BuildContext context,
    DocumentSnapshot? item,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?['name']);
    final descriptionController = TextEditingController(
      text: item?['description'],
    );
    final priceController = TextEditingController(
      text: item?['price']?.toString(),
    );
    final categoryController = TextEditingController(text: item?['category']);
    bool isAvailable = item?['isAvailable'] ?? true;
    String? currentImageUrl = item?['imageUrl'];
    XFile? pickedImage;
    bool isUploading = false;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF252528) : Colors.white;
    final inputColor = isDark ? const Color(0xFF161618) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setSheetState) {
            Future<void> saveMenuItem() async {
              if (!formKey.currentState!.validate()) return;
              setSheetState(() => isUploading = true);

              String imageUrl = currentImageUrl ?? '';
              if (pickedImage != null) {
                final uploadedUrl = await CloudinaryService.uploadImage(
                  pickedImage!,
                );
                if (uploadedUrl != null) imageUrl = uploadedUrl;
              }

              final menuItemData = {
                'name': nameController.text,
                'description': descriptionController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'category': categoryController.text,
                'isAvailable': isAvailable,
                'imageUrl': imageUrl,
              };

              if (item == null) {
                await _firestore.collection('cafeteria_menu').add(menuItemData);
              } else {
                await item.reference.update(menuItemData);
              }

              if (ctx.mounted) Navigator.pop(ctx);
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    item == null ? 'Add Menu Item' : 'Edit Item',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final img = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (img != null) {
                                  setSheetState(() => pickedImage = img);
                                }
                              },
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: inputColor,
                                  borderRadius: BorderRadius.circular(20),
                                  image:
                                      pickedImage != null
                                          ? DecorationImage(
                                            image: FileImage(
                                              File(pickedImage!.path),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                          : (currentImageUrl != null &&
                                                  currentImageUrl.isNotEmpty
                                              ? DecorationImage(
                                                image: NetworkImage(
                                                  currentImageUrl,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : null),
                                ),
                                child:
                                    (pickedImage == null &&
                                            (currentImageUrl == null ||
                                                currentImageUrl.isEmpty))
                                        ? Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 40,
                                          color: Colors.grey.shade400,
                                        )
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                              nameController,
                              'Item Name',
                              inputColor,
                              textColor,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              priceController,
                              'Price (₹)',
                              inputColor,
                              textColor,
                              isNumber: true,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              categoryController,
                              'Category (e.g., Snacks)',
                              inputColor,
                              textColor,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              descriptionController,
                              'Description',
                              inputColor,
                              textColor,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: Text(
                                'Available for Order',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              value: isAvailable,
                              onChanged:
                                  (val) =>
                                      setSheetState(() => isAvailable = val),
                              activeThumbColor: const Color(0xFFFF9A44),
                              contentPadding: EdgeInsets.zero,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isUploading ? null : saveMenuItem,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9A44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child:
                                    isUploading
                                        ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : Text(
                                          "Save Item",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    Color bgColor,
    Color textColor, {
    bool isNumber = false,
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
        filled: true,
        fillColor: bgColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Manage Menu',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuSheet(context, null),
        backgroundColor: const Color(0xFFFF9A44),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('cafeteria_menu')
                .orderBy('category')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF9A44)),
            );
          }

          final items = snapshot.data!.docs;
          if (items.isEmpty) {
            return Center(
              child: Text("Menu is empty", style: TextStyle(color: textColor)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;
              final isAvailable = data['isAvailable'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                      ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        data['imageUrl'] != null &&
                                data['imageUrl'].toString().isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: data['imageUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : Container(
                              width: 50,
                              height: 50,
                              color:
                                  isDark
                                      ? Colors.black12
                                      : Colors.grey.shade100,
                              child: const Icon(
                                Icons.fastfood,
                                color: Colors.grey,
                              ),
                            ),
                  ),
                  title: Text(
                    data['name'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  subtitle: Text(
                    '₹${data['price']} • ${data['category']}',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isAvailable,
                        onChanged:
                            (val) =>
                                item.reference.update({'isAvailable': val}),
                        activeThumbColor: const Color(0xFFFF9A44),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        color: textColor,
                        onPressed: () => _showMenuSheet(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: () => item.reference.delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
