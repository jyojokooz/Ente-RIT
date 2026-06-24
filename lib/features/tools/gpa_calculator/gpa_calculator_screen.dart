// ===============================
// FILE NAME: gpa_calculator_screen.dart
// FILE PATH: lib/features/tools/gpa_calculator/gpa_calculator_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _subjects = [];
  final List<Map<String, dynamic>> _semesters = []; // saved semester results
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  // KTU Grading System
  static const Map<String, double> gradePoints = {
    'S': 10.0,
    'A+': 9.0,
    'A': 8.5,
    'B+': 8.0,
    'B': 7.0,
    'C+': 6.0,
    'C': 5.5,
    'D': 5.0,
    'P': 4.0,
    'F': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );
    _fabController.forward();
    _loadSemesters();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('gpa_semesters');
    if (data != null) {
      setState(() {
        _semesters.addAll(
          List<Map<String, dynamic>>.from(jsonDecode(data)),
        );
      });
    }
  }

  Future<void> _saveSemesters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gpa_semesters', jsonEncode(_semesters));
  }

  double get _currentSGPA {
    if (_subjects.isEmpty) return 0.0;
    double totalCredits = 0;
    double totalGradePoints = 0;
    for (final s in _subjects) {
      final credits = (s['credits'] as num).toDouble();
      final grade = s['grade'] as String;
      totalCredits += credits;
      totalGradePoints += credits * (gradePoints[grade] ?? 0);
    }
    return totalCredits > 0 ? totalGradePoints / totalCredits : 0;
  }

  double get _cgpa {
    if (_semesters.isEmpty && _subjects.isEmpty) return 0.0;
    double totalCredits = 0;
    double totalGradePoints = 0;
    for (final sem in _semesters) {
      totalCredits += (sem['totalCredits'] as num).toDouble();
      totalGradePoints += (sem['totalGradePoints'] as num).toDouble();
    }
    // Add current unsaved subjects
    for (final s in _subjects) {
      final credits = (s['credits'] as num).toDouble();
      final grade = s['grade'] as String;
      totalCredits += credits;
      totalGradePoints += credits * (gradePoints[grade] ?? 0);
    }
    return totalCredits > 0 ? totalGradePoints / totalCredits : 0;
  }

  void _addSubject() {
    final nameController = TextEditingController();
    int selectedCredits = 3;
    String selectedGrade = 'S';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final sheetColor = isDark ? const Color(0xFF1C1C22) : Colors.white;

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
                    'Add Subject',
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
                      prefixIcon: Icon(
                        Icons.book_rounded,
                        color: const Color(0xFF7B61FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Credits',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedCredits,
                                  dropdownColor: sheetColor,
                                  isExpanded: true,
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  items: [1, 2, 3, 4, 5]
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text('$c'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setSheetState(
                                      () => selectedCredits = val!,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Grade',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedGrade,
                                  dropdownColor: sheetColor,
                                  isExpanded: true,
                                  style: GoogleFonts.poppins(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  items: gradePoints.keys
                                      .map(
                                        (g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(
                                            '$g (${gradePoints[g]})',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    setSheetState(
                                      () => selectedGrade = val!,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) return;
                        setState(() {
                          _subjects.add({
                            'name': nameController.text.trim(),
                            'credits': selectedCredits,
                            'grade': selectedGrade,
                          });
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7B61FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Subject',
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

  void _saveSemester() {
    if (_subjects.isEmpty) return;
    double totalCredits = 0;
    double totalGradePoints = 0;
    for (final s in _subjects) {
      final credits = (s['credits'] as num).toDouble();
      final grade = s['grade'] as String;
      totalCredits += credits;
      totalGradePoints += credits * (gradePoints[grade] ?? 0);
    }
    setState(() {
      _semesters.add({
        'semesterNo': _semesters.length + 1,
        'sgpa': totalCredits > 0 ? totalGradePoints / totalCredits : 0,
        'totalCredits': totalCredits,
        'totalGradePoints': totalGradePoints,
        'subjectCount': _subjects.length,
      });
      _subjects.clear();
    });
    _saveSemesters();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semester ${_semesters.length} saved!',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF7B61FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          'GPA Calculator',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_subjects.isNotEmpty)
            TextButton.icon(
              onPressed: _saveSemester,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(
                'Save Sem',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF7B61FF),
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- GPA Display Cards ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _GpaDisplayCard(
                      title: 'Current SGPA',
                      value: _currentSGPA.toStringAsFixed(2),
                      gradient: const [Color(0xFF7B61FF), Color(0xFFB165FF)],
                      icon: Icons.analytics_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _GpaDisplayCard(
                      title: 'Overall CGPA',
                      value: _cgpa.toStringAsFixed(2),
                      gradient: const [Color(0xFFFF4B72), Color(0xFFFF9A44)],
                      icon: Icons.school_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Saved Semesters ---
          if (_semesters.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Saved Semesters',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _semesters.length,
                  itemBuilder: (context, index) {
                    final sem = _semesters[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF7B61FF).withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sem ${sem['semesterNo']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (sem['sgpa'] as double).toStringAsFixed(2),
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF7B61FF),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // --- Current Subjects Header ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Subjects',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${_subjects.length} added',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Subject List ---
          if (_subjects.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 64,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap + to add subjects',
                      style: GoogleFonts.poppins(
                        color: subtitleColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subject = _subjects[index];
                  final grade = subject['grade'] as String;
                  final gp = gradePoints[grade] ?? 0;
                  final gradeColor = gp >= 8
                      ? const Color(0xFF43E97B)
                      : gp >= 6
                          ? const Color(0xFFFFD200)
                          : const Color(0xFFFF4B72);

                  return Dismissible(
                    key: Key('$index-${subject['name']}'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) {
                      setState(() => _subjects.removeAt(index));
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: gradeColor.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: gradeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                grade,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: gradeColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  '${subject['credits']} Credits • GP: $gp',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: subtitleColor,
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
                childCount: _subjects.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: _addSubject,
          backgroundColor: const Color(0xFF7B61FF),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _GpaDisplayCard extends StatelessWidget {
  final String title;
  final String value;
  final List<Color> gradient;
  final IconData icon;

  const _GpaDisplayCard({
    required this.title,
    required this.value,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
