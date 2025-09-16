import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CafeteriaScreen extends StatelessWidget {
  const CafeteriaScreen({super.key});

  // --- Logic to handle placing an order ---
  Future<void> _placeOrder(
    BuildContext context,
    Map<String, dynamic> itemData,
  ) async {
    // --- FIX: Store the ScaffoldMessenger before the async gap ---
    // This is a robust way to handle the context.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to place an order.'),
        ),
      );
      return;
    }

    try {
      // This is the "async gap" where the context could become invalid.
      await FirebaseFirestore.instance.collection('cafeteria_orders').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'No Name',
        'itemName': itemData['name'],
        'itemPrice': itemData['price'],
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Placed', // e.g., Placed, Preparing, Ready, Completed
      });

      // --- FIX: Check if the widget is still mounted BEFORE using the context ---
      if (!context.mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Successfully placed order for ${itemData['name']}!'),
        ),
      );
    } catch (e) {
      // --- FIX: Also check if mounted in the catch block ---
      if (!context.mounted) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cafeteria Menu', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('cafeteria_menu')
                .where('isAvailable', isEqualTo: true)
                .orderBy('category')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No items are currently available.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final Map<String, List<QueryDocumentSnapshot>> groupedItems = {};
          for (var doc in snapshot.data!.docs) {
            final category = doc['category'] as String? ?? 'Others';
            if (groupedItems[category] == null) {
              groupedItems[category] = [];
            }
            groupedItems[category]!.add(doc);
          }

          final categories = groupedItems.keys.toList();

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final items = groupedItems[category]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.yellow,
                      ),
                    ),
                  ),
                  ...items.map((item) {
                    final data = item.data() as Map<String, dynamic>;
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  data['imageUrl'] != null &&
                                          data['imageUrl'].isNotEmpty
                                      ? Image.network(
                                        data['imageUrl'],
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  height: 80,
                                                  width: 80,
                                                  color: Colors.black26,
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                  ),
                                                ),
                                      )
                                      : Container(
                                        height: 80,
                                        width: 80,
                                        color: Colors.black26,
                                        child: const Icon(
                                          Icons.fastfood,
                                          size: 40,
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'No Name',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['description'] ?? 'No description.',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${data['price']?.toStringAsFixed(2) ?? '0.00'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _placeOrder(context, data);
                              },
                              child: const Text('Order'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
