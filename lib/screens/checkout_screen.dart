import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends StatefulWidget {
  // We receive the cart as a parameter
  final Map<DocumentSnapshot, int> cart;
  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;
  bool _isPlacingOrder = false;

  // Local cart variable that we can modify
  late Map<DocumentSnapshot, int> _editableCart;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the cart when the widget is initialized
    _editableCart = Map.from(widget.cart);
  }

  // --- NEW: Method to add an item ---
  void _addToCart(DocumentSnapshot item) {
    setState(() {
      _editableCart.update(item, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  // --- NEW: Method to remove an item ---
  void _removeFromCart(DocumentSnapshot item) {
    setState(() {
      if (_editableCart.containsKey(item)) {
        if (_editableCart[item]! > 1) {
          _editableCart.update(item, (value) => value - 1);
        } else {
          _editableCart.remove(item);
          // If the cart becomes empty, go back to the menu screen.
          if (_editableCart.isEmpty) {
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  double get _cartTotal {
    double total = 0.0;
    _editableCart.forEach((item, quantity) {
      final price = (item.data() as Map<String, dynamic>)['price'] ?? 0.0;
      total += price * quantity;
    });
    return total;
  }

  Future<void> _placeOrder() async {
    // ... This method remains the same, but now uses _editableCart ...
    if (_pickupDate == null || _pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup date and time.')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      /* ... error handling ... */
      return;
    }

    final pickupDateTime = Timestamp.fromDate(
      DateTime(
        _pickupDate!.year,
        _pickupDate!.month,
        _pickupDate!.day,
        _pickupTime!.hour,
        _pickupTime!.minute,
      ),
    );

    final orderItems =
        _editableCart.entries.map((entry) {
          final itemData = entry.key.data() as Map<String, dynamic>;
          return {
            'itemId': entry.key.id,
            'itemName': itemData['name'],
            'quantity': entry.value,
            'price': itemData['price'],
          };
        }).toList();

    try {
      await FirebaseFirestore.instance.collection('cafeteria_orders').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'N/A',
        'items': orderItems,
        'totalPrice': _cartTotal,
        'orderStatus': 'Placed',
        'pickupTime': pickupDateTime,
        'orderTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // This will pop all the way back to the MainScreen, and then the cafeteria screen will clear its cart.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // ... error handling ...
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Confirm Order', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Order Summary',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // --- THIS IS THE UPDATED ORDER SUMMARY WIDGET ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Dynamically build the list of items with +/- controls
                ..._editableCart.entries.map((entry) {
                  final itemDoc = entry.key;
                  final item = itemDoc.data() as Map<String, dynamic>;
                  final quantity = entry.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item['name']} (x$quantity)',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ),
                        // +/- Counter
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () => _removeFromCart(itemDoc),
                              ),
                              Text(
                                quantity.toString(),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () => _addToCart(itemDoc),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Total',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Text(
                    '₹${_cartTotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.yellow,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Text(
            'Schedule Pickup',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Schedule Pickup logic is unchanged
          ListTile(
            leading: const Icon(
              Icons.date_range_outlined,
              color: Colors.yellow,
            ),
            title: Text(
              _pickupDate == null
                  ? 'Select Pickup Date'
                  : DateFormat.yMMMMd().format(_pickupDate!),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (date != null) setState(() => _pickupDate = date);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.access_time_outlined,
              color: Colors.yellow,
            ),
            title: Text(
              _pickupTime == null
                  ? 'Select Pickup Time'
                  : _pickupTime!.format(context),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (time != null) setState(() => _pickupTime = time);
            },
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child:
              _isPlacingOrder
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                  : Text(
                    'Place Pre-Book Order',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
        ),
      ),
    );
  }
}
