import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:uuid/uuid.dart'; // <-- THIS LINE HAS BEEN REMOVED

// Import the Cloudinary service
import '../../services/cloudinary_service.dart';

class AdminManageCafeteriaMenuScreen extends StatefulWidget {
  const AdminManageCafeteriaMenuScreen({super.key});

  @override
  State<AdminManageCafeteriaMenuScreen> createState() =>
      _AdminManageCafeteriaMenuScreenState();
}

class _AdminManageCafeteriaMenuScreenState
    extends State<AdminManageCafeteriaMenuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _showMenuItemDialog(
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

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> pickImage() async {
              final image = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (image != null) {
                setDialogState(() {
                  pickedImage = image;
                });
              }
            }

            Future<void> saveMenuItem() async {
              if (!formKey.currentState!.validate()) return;

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);

              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Saving item...')),
              );

              String imageUrl = currentImageUrl ?? '';
              if (pickedImage != null) {
                final uploadedUrl = await CloudinaryService.uploadImage(
                  pickedImage!,
                );
                if (uploadedUrl != null) {
                  imageUrl = uploadedUrl;
                } else {
                  if (!context.mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Image upload failed. Please try again.'),
                    ),
                  );
                  return;
                }
              }

              final menuItemData = {
                'name': nameController.text,
                'description': descriptionController.text,
                'price': double.tryParse(priceController.text) ?? 0.0,
                'category': categoryController.text,
                'isAvailable': isAvailable,
                'imageUrl': imageUrl,
              };

              try {
                if (item == null) {
                  await _firestore
                      .collection('cafeteria_menu')
                      .add(menuItemData);
                } else {
                  await item.reference.update(menuItemData);
                }

                if (!ctx.mounted) return;
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Item saved successfully!')),
                );
              } catch (e) {
                if (!context.mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('Failed to save item: $e')),
                );
              }
            }

            return AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: Text(item == null ? 'Add Menu Item' : 'Edit Menu Item'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade700),
                            image:
                                pickedImage != null
                                    ? DecorationImage(
                                      image: FileImage(File(pickedImage!.path)),
                                      fit: BoxFit.cover,
                                    )
                                    : (currentImageUrl != null &&
                                            currentImageUrl.isNotEmpty
                                        ? DecorationImage(
                                          image: NetworkImage(currentImageUrl),
                                          fit: BoxFit.cover,
                                        )
                                        : null),
                          ),
                          child:
                              (pickedImage == null &&
                                      (currentImageUrl == null ||
                                          currentImageUrl.isEmpty))
                                  ? const Center(
                                    child: Icon(
                                      Icons.add_a_photo,
                                      color: Colors.white70,
                                      size: 40,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category (e.g., Lunch, Snacks)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      SwitchListTile(
                        title: const Text('Is Available?'),
                        value: isAvailable,
                        onChanged:
                            (val) => setDialogState(() => isAvailable = val),
                        activeColor: Colors.yellow,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saveMenuItem,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Menu', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('cafeteria_menu')
                .orderBy('category')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No menu items found.'));
          }

          final items = snapshot.data!.docs;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data() as Map<String, dynamic>;
              final imageUrl = data['imageUrl'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade800,
                child: ListTile(
                  leading:
                      imageUrl != null && imageUrl.isNotEmpty
                          ? CircleAvatar(
                            backgroundImage: NetworkImage(imageUrl),
                          )
                          : const CircleAvatar(child: Icon(Icons.fastfood)),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text(
                    '${data['category'] ?? 'Uncategorized'} - ₹${data['price']?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: data['isAvailable'] ?? true,
                        onChanged:
                            (val) =>
                                item.reference.update({'isAvailable': val}),
                        activeColor: Colors.yellow,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showMenuItemDialog(context, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          await item.reference.delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMenuItemDialog(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
