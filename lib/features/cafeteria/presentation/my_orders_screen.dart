// ===============================
// FILE NAME: my_orders_screen.dart
// FILE PATH: lib/screens/my_orders_screen.dart
// ===============================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return const Color(0xFF00C6FB); // Blue
      case 'Preparing':
        return const Color(0xFFFF9A44); // Orange
      case 'Ready for Pickup':
        return const Color(0xFF43E97B); // Green
      case 'Completed':
        return Colors.grey;
      case 'Cancelled':
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161618) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body:
          user == null
              ? Center(
                child: Text(
                  "Please log in to see your orders.",
                  style: TextStyle(color: textColor),
                ),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('cafeteria_orders')
                        .where('userId', isEqualTo: user.uid)
                        .orderBy('orderTimestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF9A44),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            size: 60,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No orders placed yet.',
                            style: GoogleFonts.poppins(
                              color: subtitleColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order =
                          orders[index].data() as Map<String, dynamic>;
                      final pickupTime =
                          (order['pickupTime'] as Timestamp).toDate();
                      final status = order['orderStatus'] ?? 'Unknown';
                      final statusColor = _getStatusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(24),
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
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: subtitleColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat(
                                          'MMM dd, h:mm a',
                                        ).format(pickupTime),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Divider(
                                  color:
                                      isDark ? Colors.white10 : Colors.black12,
                                  height: 1,
                                ),
                              ),
                              ...(order['items'] as List).map((item) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color:
                                              isDark
                                                  ? const Color(0xFF161618)
                                                  : Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${item['quantity']}x',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          item['itemName'],
                                          style: GoogleFonts.poppins(
                                            color: textColor,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '₹${order['totalPrice'].toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    fontSize: 18,
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
}
