// ===============================
// FILE NAME: attendance_tracker_screen.dart
// FILE PATH: lib/features/tools/attendance_tracker/attendance_tracker_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceTrackerScreen extends StatefulWidget {
  const AttendanceTrackerScreen({super.key});

  @override
  State<AttendanceTrackerScreen> createState() =>
      _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _subjects = [];
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('attendance_data');
    if (data != null) {
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
    _animController.forward();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('attendance_data', jsonEncode(_subjects));
  }

  Color _getAttendanceColor(double percentage) {
    if (percentage >= 75) return const Color(0xFF43E97B);
    if (percentage >= 65) return const Color(0xFFFFD200);
    return const Color(0xFFFF4B72);
  }

  double _getPercentage(Map<String, dynamic> subject) {
    final total = (subject['total'] as int?) ?? 0;
    final present = (subject['present'] as int?) ?? 0;
    if (total == 0) return 0;
    return (present / total) * 100;
  }

  void _addSubject() {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1C1C22) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add Subject',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  labelText: 'Subject Name',
                  labelStyle: GoogleFonts.poppins(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.book_rounded,
                    color: Color(0xFF00B4D8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    setState(() {
                      _subjects.add({
                        'name': controller.text.trim(),
                        'total': 0,
                        'present': 0,
                      });
                    });
                    _saveData();
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B4D8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _markAttendance(int index, bool present) {
    setState(() {
      _subjects[index]['total'] = (_subjects[index]['total'] as int) + 1;
      if (present) {
        _subjects[index]['present'] = (_subjects[index]['present'] as int) + 1;
      }
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    // Overall attendance
    int totalAll = 0, presentAll = 0;
    for (final s in _subjects) {
      totalAll += (s['total'] as int?) ?? 0;
      presentAll += (s['present'] as int?) ?? 0;
    }
    final overallPct = totalAll > 0 ? (presentAll / totalAll) * 100 : 0.0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attendance Tracker',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Overall Attendance Card ---
          Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00B4D8),
                  const Color(0xFF0077B6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00B4D8).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${overallPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$presentAll / $totalAll classes',
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: overallPct / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                      Icon(
                        Icons.school_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Subject List ---
          Expanded(
            child: _subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fact_check_outlined,
                          size: 64,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add subjects to start tracking',
                          style: GoogleFonts.poppins(
                            color: subtitleColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      final subject = _subjects[index];
                      final pct = _getPercentage(subject);
                      final color = _getAttendanceColor(pct);
                      final total = subject['total'] as int;
                      final present = subject['present'] as int;

                      return Dismissible(
                        key: Key('att-$index-${subject['name']}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) {
                          setState(() => _subjects.removeAt(index));
                          _saveData();
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.book_rounded,
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject['name'],
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '$present / $total classes',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: subtitleColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${pct.toStringAsFixed(0)}%',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? present / total : 0,
                                  minHeight: 6,
                                  backgroundColor: color.withOpacity(0.1),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: _AttendanceButton(
                                      label: 'Present',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF43E97B),
                                      onTap: () =>
                                          _markAttendance(index, true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _AttendanceButton(
                                      label: 'Absent',
                                      icon: Icons.cancel_rounded,
                                      color: const Color(0xFFFF4B72),
                                      onTap: () =>
                                          _markAttendance(index, false),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        backgroundColor: const Color(0xFF00B4D8),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _AttendanceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
