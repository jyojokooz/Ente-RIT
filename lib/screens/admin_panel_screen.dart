import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'admin/admin_manage_users_screen.dart';
import 'admin/admin_manage_posts_screen.dart';
import 'admin/admin_manage_departments_screen.dart';
import 'admin/admin_manage_events_screen.dart';
import 'admin/admin_manage_lostfound_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> managementCards = [
      {
        'label': 'Manage Users',
        'icon': Icons.people_alt_outlined,
        'color': Colors.blue.shade400,
        'screen': const AdminManageUsersScreen(),
      },
      {
        'label': 'Manage Posts',
        'icon': Icons.article_outlined,
        'color': Colors.orange.shade400,
        'screen': const AdminManagePostsScreen(),
      },
      {
        'label': 'Manage Events',
        'icon': Icons.event_available_outlined,
        'color': Colors.green.shade400,
        'screen': const AdminManageEventsScreen(),
      },
      {
        'label': 'Lost & Found',
        'icon': Icons.find_in_page_outlined,
        'color': Colors.red.shade400,
        'screen': const AdminManageLostFoundScreen(),
      },
      {
        'label': 'Departments',
        'icon': Icons.school_outlined,
        'color': Colors.purple.shade400,
        'screen': const AdminManageDepartmentsScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "At a Glance",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _StatCard(
                  collection: 'users',
                  title: 'Total Users',
                  icon: Icons.people_alt_outlined,
                  color: Colors.blue,
                ),
                _StatCard(
                  collection: 'posts',
                  title: 'Total Posts',
                  icon: Icons.article_outlined,
                  color: Colors.orange,
                ),
                _StatCard(
                  collection: 'events',
                  title: 'Events',
                  icon: Icons.event_available_outlined,
                  color: Colors.green,
                ),
                _StatCard(
                  collection: 'lost_and_found',
                  title: 'L&F Items',
                  icon: Icons.find_in_page_outlined,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              "Recent Activity",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const UserActivityChart(),
            const SizedBox(height: 32),
            Text(
              "Management",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: managementCards.length,
              itemBuilder: (context, index) {
                final card = managementCards[index];
                return _buildManagementCard(
                  context: context,
                  label: card['label'],
                  icon: card['icon'],
                  color: card['color'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => card['screen']),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: color),
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String collection;
  final String title;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.collection,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection(collection)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text(
                          '...',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          snapshot.data!.docs.length.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
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
}

class UserActivityChart extends StatelessWidget {
  const UserActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        color: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .where(
                      'createdAt',
                      isGreaterThanOrEqualTo: DateTime.now().subtract(
                        const Duration(days: 7),
                      ),
                    )
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final Map<int, int> userCountsByDay = {
                for (var i = 0; i < 7; i++) i: 0,
              };
              final today = DateTime.now();

              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data.containsKey('createdAt') &&
                    data['createdAt'] is Timestamp) {
                  final createdAt = (data['createdAt'] as Timestamp).toDate();
                  final dayDifference = today.difference(createdAt).inDays;
                  if (dayDifference >= 0 && dayDifference < 7) {
                    userCountsByDay[6 - dayDifference] =
                        (userCountsByDay[6 - dayDifference] ?? 0) + 1;
                  }
                }
              }

              final maxY =
                  (userCountsByDay.values.isEmpty
                          ? 0
                          : userCountsByDay.values.reduce(
                            (a, b) => a > b ? a : b,
                          ))
                      .toDouble();

              return BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 5 : maxY + 2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final day = DateTime.now().subtract(
                            Duration(days: 6 - value.toInt()),
                          );
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('E').format(day),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // --- THIS IS THE FIX: Added curly braces {} ---
                          if (value == 0 ||
                              value % 2 != 0 && value != meta.max) {
                            return const Text('');
                          }
                          // --- END OF FIX ---
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade800,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: userCountsByDay[index]!.toDouble(),
                          color: Colors.yellow,
                          width: 16,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
