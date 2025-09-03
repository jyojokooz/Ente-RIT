// lib/screens/admin/admin_manage_features_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminManageFeaturesScreen extends StatefulWidget {
  const AdminManageFeaturesScreen({super.key});

  @override
  // FIX: Renamed state class to be public.
  AdminManageFeaturesScreenState createState() =>
      AdminManageFeaturesScreenState();
}

// FIX: Renamed state class to be public.
class AdminManageFeaturesScreenState extends State<AdminManageFeaturesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showFeatureDialog({DocumentSnapshot? doc}) {
    // FIX: Removed leading underscores from local variables.
    final titleController = TextEditingController(
      text: doc != null ? doc['title'] : '',
    );
    final imageUrlController = TextEditingController(
      text: doc != null ? doc['imageUrl'] : '',
    );
    final routeController = TextEditingController(
      text: doc != null ? doc['navigationRoute'] : '',
    );
    final orderController = TextEditingController(
      text: doc != null ? doc['order'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Text(
            doc == null ? 'Add Feature Card' : 'Edit Feature Card',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: imageUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: routeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Navigation Route (e.g., /departments)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                TextField(
                  controller: orderController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Order (e.g., 1, 2, 3)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final imageUrl = imageUrlController.text.trim();
                final route = routeController.text.trim();
                final order = int.tryParse(orderController.text.trim()) ?? 0;

                if (title.isEmpty || imageUrl.isEmpty || route.isEmpty) {
                  return;
                }

                final data = {
                  'title': title,
                  'imageUrl': imageUrl,
                  'navigationRoute': route,
                  'order': order,
                  'createdAt': FieldValue.serverTimestamp(),
                };

                if (doc == null) {
                  await _firestore.collection('features').add(data);
                } else {
                  await _firestore
                      .collection('features')
                      .doc(doc.id)
                      .update(data);
                }

                // FIX: Added guard clause to ensure context is valid after async gap.
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Manage Features',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFeatureDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('features').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(doc['imageUrl']),
                    onBackgroundImageError: (e, s) => {}, // Handle error
                  ),
                  title: Text(
                    doc['title'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Order: ${doc['order']} | Route: ${doc['navigationRoute']}",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFeatureDialog(doc: doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _firestore
                              .collection('features')
                              .doc(doc.id)
                              .delete();
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
    );
  }
}
