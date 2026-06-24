// ===============================
// FILE NAME: exam_countdown_screen.dart
// FILE PATH: lib/features/tools/exam_countdown/exam_countdown_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExamCountdownScreen extends StatefulWidget {
  const ExamCountdownScreen({super.key});

  @override
  State<ExamCountdownScreen> createState() => _ExamCountdownScreenState();
}

class _ExamCountdownScreenState extends State<ExamCountdownScreen> {
  List<Map<String, dynamic>> _exams = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadExams();
    // Tick every second for live countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('exam_countdown_data');
    if (data != null) {
      setState(() {
        _exams = List<Map<String, dynamic>>.from(jsonDecode(data));
        _sortExams();
      });
    }
  }

  Future<void> _saveExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exam_countdown_data', jsonEncode(_exams));
  }

  void _sortExams() {
    _exams.sort((a, b) {
      final dateA = DateTime.parse(a['date']);
      final dateB = DateTime.parse(b['date']);
      return dateA.compareTo(dateB);
    });
  }

  void _addExam() async {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1C1C22) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    'Add Exam',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Exam Name',
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
                        Icons.quiz_rounded,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setSheetState(() => selectedDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: ctx,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setSheetState(() => selectedTime = time);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 18,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedTime.format(ctx),
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        final examDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        setState(() {
                          _exams.add({
                            'name': nameController.text.trim(),
                            'date': examDateTime.toIso8601String(),
                          });
                          _sortExams();
                        });
                        _saveExams();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Exam',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF8F9FE);
    final cardColor = isDark ? const Color(0xFF1C1C22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white54 : Colors.black54;

    // Split exams into upcoming and past
    final now = DateTime.now();
    final upcoming =
        _exams.where((e) => DateTime.parse(e['date']).isAfter(now)).toList();
    final past =
        _exams.where((e) => !DateTime.parse(e['date']).isAfter(now)).toList();

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
          'Exam Countdown',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
      ),
      body: _exams.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 80,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exams scheduled',
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add an exam',
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                if (upcoming.isNotEmpty) ...[
                  // --- Next Exam Hero Card ---
                  _NextExamHeroCard(
                    exam: upcoming.first,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 24),

                  if (upcoming.length > 1) ...[
                    Text(
                      'Upcoming',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...upcoming.skip(1).map(
                          (exam) => _ExamListTile(
                            exam: exam,
                            cardColor: cardColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            onDelete: () {
                              setState(() => _exams.remove(exam));
                              _saveExams();
                            },
                          ),
                        ),
                  ],
                ],
                if (past.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Past Exams',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...past.reversed.map(
                    (exam) => Opacity(
                      opacity: 0.5,
                      child: _ExamListTile(
                        exam: exam,
                        cardColor: cardColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        onDelete: () {
                          setState(() => _exams.remove(exam));
                          _saveExams();
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExam,
        backgroundColor: const Color(0xFFFF6B6B),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _NextExamHeroCard extends StatelessWidget {
  final Map<String, dynamic> exam;
  final Color cardColor;

  const _NextExamHeroCard({required this.exam, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    final examDate = DateTime.parse(exam['date']);
    final now = DateTime.now();
    final diff = examDate.difference(now);

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'NEXT EXAM',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exam['name'],
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // Countdown Blocks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CountdownBlock(value: '$days', label: 'DAYS'),
              _CountdownBlock(value: hours.toString().padLeft(2, '0'), label: 'HRS'),
              _CountdownBlock(
                  value: minutes.toString().padLeft(2, '0'), label: 'MIN'),
              _CountdownBlock(
                  value: seconds.toString().padLeft(2, '0'), label: 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownBlock extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamListTile extends StatelessWidget {
  final Map<String, dynamic> exam;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onDelete;

  const _ExamListTile({
    required this.exam,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final examDate = DateTime.parse(exam['date']);
    final diff = examDate.difference(DateTime.now());
    final daysLeft = diff.inDays;

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${examDate.day}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFFFF6B6B),
                    height: 1,
                  ),
                ),
                Text(
                  months[examDate.month - 1],
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                Text(
                  daysLeft > 0 ? '$daysLeft days left' : 'Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.close_rounded,
              color: subtitleColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
