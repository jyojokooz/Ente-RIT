import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// --- THIS IS THE FIX ---
import 'package:intl/intl.dart';
// --- END OF FIX ---

class AdminViewCafeteriaOrdersScreen extends StatefulWidget {
  const AdminViewCafeteriaOrdersScreen({super.key});

  @override
  State<AdminViewCafeteriaOrdersScreen> createState() =>
      _AdminViewCafeteriaOrdersScreenState();
}

class _AdminViewCafeteriaOrdersScreenState
    extends State<AdminViewCafeteriaOrdersScreen> {
  // Method to update the status of an order
  Future<void> _updateOrderStatus(
    DocumentSnapshot orderDoc,
    String newStatus,
  ) async {
    await orderDoc.reference.update({'orderStatus': newStatus});
  }

  // Shows a dialog with status options
  void _showStatusUpdateDialog(DocumentSnapshot orderDoc) {
    const statuses = ['Placed', 'Preparing', 'Ready for Pickup', 'Completed'];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade800,
          title: const Text('Update Order Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                statuses.map((status) {
                  return ListTile(
                    title: Text(status),
                    onTap: () {
                      Navigator.of(context).pop();
                      _updateOrderStatus(orderDoc, status);
                    },
                  );
                }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
        title: Text('Manage Food Orders', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('cafeteria_orders')
                .orderBy('pickupTime', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          final orders = snapshot.data!.docs;

          if (orders.isEmpty) {
            return const Center(child: Text('No orders found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final order = orderDoc.data() as Map<String, dynamic>;
              final pickupTime = (order['pickupTime'] as Timestamp).toDate();

              return Card(
                color: Colors.grey.shade800,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup: ${DateFormat.yMMMMd().add_jm().format(pickupTime)}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('Ordered by: ${order['userName'] ?? 'N/A'}'),
                      const Divider(height: 20, color: Colors.white24),
                      ...(order['items'] as List).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• ${item['itemName']} (x${item['quantity']})',
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: ₹${order['totalPrice']?.toStringAsFixed(2) ?? '0.00'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.yellow,
                          ),
                        ),
                      ),
                      const Divider(height: 20, color: Colors.white24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status:',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '${order['orderStatus']}',
                                style: TextStyle(
                                  color: _getStatusColor(order['orderStatus']),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (order['orderStatus'] != 'Completed')
                            ElevatedButton(
                              onPressed:
                                  () => _showStatusUpdateDialog(orderDoc),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Update'),
                            ),
                        ],
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return Colors.blue.shade300;
      case 'Preparing':
        return Colors.orange.shade300;
      case 'Ready for Pickup':
        return Colors.green.shade300;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.white;
    }
  }
}
