// ===============================
// FILE NAME: cafeteria_screen.dart
// FILE PATH: lib/screens/cafeteria_screen.dart
// ===============================

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    return _cart.values.reduce((total, element) => total + element);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Cafeteria',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long_rounded, color: textColor),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
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
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF9A44)),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fastfood_rounded,
                        size: 60,
                        color: isDark ? Colors.white24 : Colors.black12,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No items currently available.',
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final Map<String, List<QueryDocumentSnapshot>> groupedItems = {};
              for (var doc in snapshot.data!.docs) {
                final category = doc['category'] as String? ?? 'Others';
                groupedItems.putIfAbsent(category, () => []).add(doc);
              }

              final categories = groupedItems.keys.toList();

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  bottom: 120,
                ), // Space for cart bar
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final items = groupedItems[category]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                      ...items.map((item) {
                        final data = item.data() as Map<String, dynamic>;
                        final int quantityInCart = _cart[item] ?? 0;
                        return _buildMenuItem(
                          item,
                          data,
                          quantityInCart,
                          isDark,
                        );
                      }),
                    ],
                  );
                },
              );
            },
          ),

          if (_cart.isNotEmpty) _buildFloatingCartBar(isDark),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    DocumentSnapshot item,
    Map<String, dynamic> data,
    int quantityInCart,
    bool isDark,
  ) {
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Image
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.black12 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                    data['imageUrl'] != null &&
                            data['imageUrl'].toString().isNotEmpty
                        ? CachedNetworkImage(
                          imageUrl: data['imageUrl'],
                          fit: BoxFit.cover,
                          placeholder:
                              (c, u) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          errorWidget:
                              (c, u, e) => Icon(
                                Icons.fastfood_rounded,
                                color: subtitleColor,
                              ),
                        )
                        : Icon(
                          Icons.fastfood_rounded,
                          color: subtitleColor,
                          size: 30,
                        ),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'No Name',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (data['description'] != null &&
                      data['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        data['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: subtitleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${data['price']?.toStringAsFixed(2) ?? '0.00'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF9A44), // Vibrant Orange
                    ),
                  ),
                ],
              ),
            ),

            // Add/Remove Controls
            quantityInCart == 0
                ? ElevatedButton(
                  onPressed: () => _addToCart(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9A44).withOpacity(0.15),
                    foregroundColor: const Color(0xFFFF9A44),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    "ADD",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9A44),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => _removeFromCart(item),
                      ),
                      Text(
                        quantityInCart.toString(),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: () => _addToCart(item),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingCartBar(bool isDark) {
    return Positioned(
      bottom: 24,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CheckoutScreen(cart: _cart)),
              ).then((orderPlaced) {
                if (orderPlaced == true && mounted) {
                  setState(() => _cart.clear());
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF9A44),
                    Color(0xFFFF3E8E),
                  ], // Orange to Pink
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9A44).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_cartItemCount items',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${_cartTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Checkout',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
