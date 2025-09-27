import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'checkout_screen.dart';
import 'my_orders_screen.dart';

class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({super.key});

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  final Map<DocumentSnapshot, int> _cart = {};

  void _addToCart(DocumentSnapshot item) {
    setState(() {
      _cart.update(item, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _removeFromCart(DocumentSnapshot item) {
    setState(() {
      if (_cart.containsKey(item)) {
        if (_cart[item]! > 1) {
          _cart.update(item, (value) => value - 1);
        } else {
          _cart.remove(item);
        }
      }
    });
  }

  double get _cartTotal {
    if (_cart.isEmpty) return 0.0;
    double total = 0.0;
    _cart.forEach((item, quantity) {
      final price = (item.data() as Map<String, dynamic>)['price'] ?? 0.0;
      total += price * quantity;
    });
    return total;
  }

  int get _cartItemCount {
    if (_cart.isEmpty) return 0;
    return _cart.values.fold(0, (sum, element) => sum + element);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cafeteria Menu', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
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
                  child: Text('No items are currently available.'),
                );
              }

              final Map<String, List<QueryDocumentSnapshot>> groupedItems = {};
              for (var doc in snapshot.data!.docs) {
                final category = doc['category'] as String? ?? 'Others';
                groupedItems.putIfAbsent(category, () => []).add(doc);
              }

              final categories = groupedItems.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 100),
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
                        final int quantityInCart = _cart[item] ?? 0;
                        return _buildMenuItem(item, data, quantityInCart);
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
          if (_cart.isNotEmpty) _buildCartBar(),
        ],
      ),
    );
  }

  // --- THIS IS THE FINAL, CORRECTED WIDGET FOR MENU ITEMS ---
  Widget _buildMenuItem(
    DocumentSnapshot item,
    Map<String, dynamic> data,
    int quantityInCart,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['imageUrl'],
                  height: 70,
                  width: 70,
                  fit: BoxFit.cover,
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
                    data['description'] ?? '',
                    style: const TextStyle(color: Colors.white70),
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

            // This is the new, fully functional Add/Remove button logic.
            // It shows an "ADD" button if the item is not in the cart,
            // otherwise it shows the counter with "+" and "-" buttons.
            quantityInCart == 0
                ? OutlinedButton(
                  onPressed: () => _addToCart(item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.yellow),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "ADD",
                    style: TextStyle(color: Colors.yellow),
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // REMOVE BUTTON
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _removeFromCart(item),
                        ),
                      ),
                      // QUANTITY TEXT
                      Text(
                        quantityInCart.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      // ADD BUTTON
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: () => _addToCart(item),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CheckoutScreen(cart: _cart)),
          ).then((orderPlaced) {
            if (orderPlaced == true && mounted) {
              setState(() {
                _cart.clear();
              });
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.yellow,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_cartItemCount items | ₹${_cartTotal.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: [
                  Text(
                    'View Cart',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.shopping_cart_checkout, color: Colors.black),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
