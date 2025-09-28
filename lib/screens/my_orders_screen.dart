import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Orders', style: GoogleFonts.poppins()),
          backgroundColor: Colors.grey.shade900,
        ),
        body: const Center(child: Text("Please log in to see your orders.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: GoogleFonts.poppins()),
        backgroundColor: Colors.grey.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('cafeteria_orders')
                .where('userId', isEqualTo: user.uid)
                .orderBy('orderTimestamp', descending: true)
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
            return Center(
              child: Text(
                'You have not placed any orders yet.',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
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
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${order['orderStatus']}',
                        style: TextStyle(
                          color: _getStatusColor(order['orderStatus']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 20),

                      // --- THIS IS THE FIX ---
                      // The unnecessary .toList() has been removed from the end of the .map() call.
                      ...(order['items'] as List).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• ${item['itemName']} (x${item['quantity']})',
                          ),
                        );
                      }),

                      // --- END OF FIX ---
                      const Divider(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: ₹${order['totalPrice'].toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.yellow,
                            fontSize: 16,
                          ),
                        ),
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
