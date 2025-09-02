import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Import the dedicated management screens from the 'admin' subfolder
import 'admin/admin_manage_users_screen.dart';
import 'admin/admin_manage_posts_screen.dart';
import 'admin/admin_manage_departments_screen.dart';
import 'admin/admin_manage_events_screen.dart';
import 'admin/admin_manage_lostfound_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- AT A GLANCE SECTION (RESTORED) ---
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
                title: 'Total Events',
                icon: Icons.event_available_outlined,
                color: Colors.green,
              ),
              _StatCard(
                collection: 'lost_and_found',
                title: 'Total L&F Items',
                icon: Icons.find_in_page_outlined,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // --- USER ACTIVITY SECTION ---
          Text(
            "User Activity",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _ActivityChartCard(
            title: "New Users / 7 Days",
            collectionName: "users",
            timestampField: "createdAt",
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            label: 'Manage All Users',
            icon: Icons.people_alt_outlined,
            color: Colors.blue.shade400,
            screen: const AdminManageUsersScreen(),
          ),
          const SizedBox(height: 32),

          // --- POSTS ACTIVITY SECTION ---
          Text(
            "Post Activity",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _ActivityChartCard(
            title: "New Posts / 7 Days",
            collectionName: "posts",
            timestampField: "timestamp",
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            label: 'Manage All Posts',
            icon: Icons.article_outlined,
            color: Colors.orange.shade400,
            screen: const AdminManagePostsScreen(),
          ),
          const SizedBox(height: 32),

          // --- EVENT ACTIVITY SECTION ---
          Text(
            "Event Activity",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _ActivityChartCard(
            title: "New Events / 7 Days",
            collectionName: "events",
            timestampField: "createdAt",
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            label: 'Manage All Events',
            icon: Icons.event_available_outlined,
            color: Colors.green.shade400,
            screen: const AdminManageEventsScreen(),
          ),
          const SizedBox(height: 32),

          // --- LOST & FOUND ACTIVITY SECTION ---
          Text(
            "Lost & Found Activity",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _ActivityChartCard(
            title: "New Items / 7 Days",
            collectionName: "lost_and_found",
            timestampField: "createdAt",
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            label: 'Manage Lost & Found',
            icon: Icons.find_in_page_outlined,
            color: Colors.red.shade400,
            screen: const AdminManageLostFoundScreen(),
          ),
          const SizedBox(height: 32),

          // --- DEPARTMENTS SECTION (No Graph, just a stat card) ---
          Text(
            "Departments",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildManagementCard(
            context: context,
            label: 'Manage Departments',
            icon: Icons.school_outlined,
            color: Colors.purple.shade400,
            screen: const AdminManageDepartmentsScreen(),
          ),
        ],
      ),
    );
  }

  // Navigation card helper
  Widget _buildManagementCard({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required Widget screen,
  }) {
    return Card(
      color: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            ),
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      ),
    );
  }
}

// Helper widget for the "At a Glance" stat cards
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

// The reusable Activity Chart Widget
class _ActivityChartCard extends StatelessWidget {
  final String title;
  final String collectionName;
  final String timestampField;
  final Color color;

  const _ActivityChartCard({
    required this.title,
    required this.collectionName,
    required this.timestampField,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: Card(
        color: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection(collectionName)
                          .where(
                            timestampField,
                            isGreaterThanOrEqualTo: DateTime.now().subtract(
                              const Duration(days: 7),
                            ),
                          )
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final Map<int, int> countsByDay = {
                      for (var i = 0; i < 7; i++) i: 0,
                    };
                    final today = DateTime.now();

                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data.containsKey(timestampField) &&
                          data[timestampField] is Timestamp) {
                        final timestamp =
                            (data[timestampField] as Timestamp).toDate();
                        final dayDifference =
                            today.difference(timestamp).inDays;
                        if (dayDifference >= 0 && dayDifference < 7) {
                          countsByDay[6 - dayDifference] =
                              (countsByDay[6 - dayDifference] ?? 0) + 1;
                        }
                      }
                    }

                    final maxY =
                        (countsByDay.values.isEmpty
                                ? 0
                                : countsByDay.values.reduce(
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
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) {
                                if (value == 0 ||
                                    (value % 2 != 0 && value != meta.max)) {
                                  return const Text('');
                                }
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
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.grey.shade800,
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: countsByDay[index]!.toDouble(),
                                color: color,
                                width: 12,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
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
            ],
          ),
        ),
      ),
    );
  }
}
