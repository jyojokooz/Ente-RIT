// cafeteria_admin_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CafeteriaAdminScreen extends StatefulWidget {
  const CafeteriaAdminScreen({super.key});

  @override
  State<CafeteriaAdminScreen> createState() => _CafeteriaAdminScreenState();
}

class _CafeteriaAdminScreenState extends State<CafeteriaAdminScreen> {
  // Method to update the status of an order in Firestore
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('cafeteria_orders')
          .doc(orderId)
          .update({'orderStatus': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to "$newStatus"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Manage Food Orders', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Listen to the live stream of all cafeteria orders
        stream:
            FirebaseFirestore.instance
                .collection('cafeteria_orders')
                .orderBy(
                  'pickupTime',
                  descending: false,
                ) // Show upcoming orders first
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No active orders found.',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              // --- THIS IS THE FIX ---
              // We are now fetching and displaying the 'userName' from the order document.
              final String userName = data['userName'] ?? 'Unknown User';
              // --- END OF FIX ---

              final List<dynamic> items = data['items'] ?? [];
              final String orderStatus = data['orderStatus'] ?? 'Unknown';
              final double totalPrice = data['totalPrice'] ?? 0.0;
              final Timestamp pickupTimestamp = data['pickupTime'];
              final String formattedPickupTime = DateFormat(
                'EEE, MMM d, h:mm a',
              ).format(pickupTimestamp.toDate());

              return Card(
                color: Colors.grey.shade900,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  // Display the user's name in the tile's title
                  title: Text(
                    'Order for: $userName',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    'Pickup: $formattedPickupTime',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  trailing: Text(
                    '₹${totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.yellow,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 24),
                          Text(
                            "Items:",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // List all items in the order
                          ...items.map(
                            (item) => Text(
                              '• ${item['itemName']} (x${item['quantity']})',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Display and allow changing the order status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status:',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              DropdownButton<String>(
                                value: orderStatus,
                                dropdownColor: Colors.grey.shade800,
                                style: GoogleFonts.poppins(
                                  color: Colors.yellow,
                                ),
                                underline: const SizedBox(),
                                items:
                                    <String>[
                                      'Placed',
                                      'Preparing',
                                      'Ready for Pickup',
                                      'Completed',
                                      'Cancelled',
                                    ].map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (String? newStatus) {
                                  if (newStatus != null) {
                                    _updateOrderStatus(orderDoc.id, newStatus);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
