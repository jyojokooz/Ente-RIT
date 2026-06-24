// ===============================
// FILE NAME: study_planner_screen.dart
// FILE PATH: lib/features/tools/study_planner/study_planner_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyPlannerScreen extends StatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  State<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<Map<String, dynamic>>> _schedule = {};

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<Color> _subjectColors = [
    Color(0xFF7B61FF),
    Color(0xFFFF4B72),
    Color(0xFF00B4D8),
    Color(0xFF43E97B),
    Color(0xFFFF9F1C),
    Color(0xFFE040FB),
    Color(0xFF4FACFE),
    Color(0xFFF7971E),
    Color(0xFF30CFD0),
    Color(0xFFAB47BC),
  ];

  @override
  void initState() {
    super.initState();
    // Find today's day index (Mon=0, Sun=6)
    int todayIndex = DateTime.now().weekday - 1; // 1=Mon -> 0
    _tabController = TabController(
      length: _days.length,
      vsync: this,
      initialIndex: todayIndex,
    );
    for (final day in _days) {
      _schedule[day] = [];
    }
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('study_planner_data');
    if (data != null) {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      setState(() {
        for (final day in _days) {
          _schedule[day] = decoded[day] != null
              ? List<Map<String, dynamic>>.from(decoded[day])
              : [];
        }
      });
    }
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_planner_data', jsonEncode(_schedule));
  }

  void _addSlot(String day) {
    final subjectController = TextEditingController();
    final roomController = TextEditingController();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    int colorIndex = _schedule[day]!.length % _subjectColors.length;

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
                    'Add Class — $day',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: subjectController,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Subject',
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
                        color: Color(0xFFFF9F1C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roomController,
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Room (optional)',
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
                        Icons.room_rounded,
                        color: Color(0xFFFF9F1C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: startTime,
                            );
                            if (t != null) {
                              setSheetState(() => startTime = t);
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                                Text(
                                  startTime.format(ctx),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: isDark ? Colors.white38 : Colors.black26,
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: ctx,
                              initialTime: endTime,
                            );
                            if (t != null) {
                              setSheetState(() => endTime = t);
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                                Text(
                                  endTime.format(ctx),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
                  const SizedBox(height: 16),
                  // Color picker
                  Text(
                    'Color',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _subjectColors.length,
                      itemBuilder: (context, i) {
                        final isSelected = colorIndex == i;
                        return GestureDetector(
                          onTap: () => setSheetState(() => colorIndex = i),
                          child: Container(
                            width: 36,
                            height: 36,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: _subjectColors[i],
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _subjectColors[i]
                                            .withOpacity(0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (subjectController.text.trim().isEmpty) return;
                        setState(() {
                          _schedule[day]!.add({
                            'subject': subjectController.text.trim(),
                            'room': roomController.text.trim(),
                            'startHour': startTime.hour,
                            'startMin': startTime.minute,
                            'endHour': endTime.hour,
                            'endMin': endTime.minute,
                            'colorIndex': colorIndex,
                          });
                          // Sort by start time
                          _schedule[day]!.sort((a, b) {
                            final aMin =
                                a['startHour'] * 60 + a['startMin'] as int;
                            final bMin =
                                b['startHour'] * 60 + b['startMin'] as int;
                            return aMin.compareTo(bMin);
                          });
                        });
                        _saveSchedule();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9F1C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Class',
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
          'Study Planner',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: const Color(0xFFFF9F1C),
          indicatorWeight: 3,
          labelColor: const Color(0xFFFF9F1C),
          unselectedLabelColor: subtitleColor,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: _days.map((d) => Tab(text: d)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.map((day) {
          final slots = _schedule[day] ?? [];

          if (slots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 64,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No classes on $day',
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a class',
                    style: GoogleFonts.poppins(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final color = _subjectColors[
                  (slot['colorIndex'] as int) % _subjectColors.length];
              final startStr =
                  '${(slot['startHour'] as int).toString().padLeft(2, '0')}:${(slot['startMin'] as int).toString().padLeft(2, '0')}';
              final endStr =
                  '${(slot['endHour'] as int).toString().padLeft(2, '0')}:${(slot['endMin'] as int).toString().padLeft(2, '0')}';

              return Dismissible(
                key: Key('$day-$index-${slot['subject']}'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  setState(() => slots.removeAt(index));
                  _saveSchedule();
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
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Color Bar
                      Container(
                        width: 5,
                        height: 80,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Time Column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    startStr,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    endStr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              // Subject Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot['subject'],
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: textColor,
                                      ),
                                    ),
                                    if ((slot['room'] as String?)
                                            ?.isNotEmpty ==
                                        true)
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 13,
                                            color: subtitleColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            slot['room'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSlot(_days[_tabController.index]),
        backgroundColor: const Color(0xFFFF9F1C),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
