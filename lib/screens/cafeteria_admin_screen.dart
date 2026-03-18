// ===============================
// FILE NAME: cafeteria_admin_screen.dart
// FILE PATH: lib/screens/cafeteria_admin_screen.dart
// ===============================

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
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('cafeteria_orders')
          .doc(orderId)
          .update({'orderStatus': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Placed':
        return const Color(0xFF00C6FB);
      case 'Preparing':
        return const Color(0xFFFF9A44);
      case 'Ready for Pickup':
        return const Color(0xFF43E97B);
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Live Orders',
          style: GoogleFonts.poppins(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('cafeteria_orders')
                .where(
                  'orderStatus',
                  isNotEqualTo: 'Completed',
                ) // Hide completed to declutter
                .orderBy('orderStatus') // Required for inequality filter
                .orderBy('pickupTime', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No active orders.',
                style: GoogleFonts.poppins(color: subtitleColor),
              ),
            );
          }

          // Sort manually since we used inequality on orderStatus
          final orders = snapshot.data!.docs;
          orders.sort(
            (a, b) => (a['pickupTime'] as Timestamp).compareTo(
              b['pickupTime'] as Timestamp,
            ),
          );

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              final data = orderDoc.data() as Map<String, dynamic>;

              final String userName = data['userName'] ?? 'Unknown User';
              final List<dynamic> items = data['items'] ?? [];
              final String orderStatus = data['orderStatus'] ?? 'Unknown';
              final Timestamp pickupTimestamp = data['pickupTime'];
              final String timeStr = DateFormat(
                'h:mm a',
              ).format(pickupTimestamp.toDate());

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(orderStatus).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(orderStatus),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${items.length} items',
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                            const SizedBox(height: 8),
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Text(
                                      '${item['quantity']}x',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: subtitleColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      item['itemName'],
                                      style: GoogleFonts.poppins(
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? const Color(0xFF161618)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: orderStatus,
                                  dropdownColor: cardColor,
                                  isExpanded: true,
                                  style: GoogleFonts.poppins(
                                    color: _getStatusColor(orderStatus),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items:
                                      [
                                            'Placed',
                                            'Preparing',
                                            'Ready for Pickup',
                                            'Completed',
                                            'Cancelled',
                                          ]
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (newStatus) {
                                    if (newStatus != null)
                                      _updateOrderStatus(
                                        orderDoc.id,
                                        newStatus,
                                      );
                                  },
                                ),
                              ),
                            ),
                          ],
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
