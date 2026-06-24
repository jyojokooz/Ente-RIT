// ===============================
// FILE NAME: hostel_services_screen.dart
// FILE PATH: lib/features/tools/hostel_services/hostel_services_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HostelServicesScreen extends StatefulWidget {
  const HostelServicesScreen({super.key});

  @override
  State<HostelServicesScreen> createState() => _HostelServicesScreenState();
}

class _HostelServicesScreenState extends State<HostelServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Map<String, Map<String, String>> _messMenu = {
    'Monday': {
      'Breakfast': 'Idli, Sambar, Chutney',
      'Lunch': 'Rice, Sambar, Cabbage Thoran, Pickle',
      'Dinner': 'Chapathi, Chicken Curry / Veg Kurma',
    },
    'Tuesday': {
      'Breakfast': 'Dosa, Chutney, Sambar',
      'Lunch': 'Rice, Moru Curry, Beans Mezhukkupuratti',
      'Dinner': 'Porotta, Egg Curry / Green Peas Curry',
    },
    'Wednesday': {
      'Breakfast': 'Puttu, Kadala Curry',
      'Lunch': 'Rice, Fish Curry / Paneer, Aviyal',
      'Dinner': 'Kanji, Payar, Pappadam, Chammanthi',
    },
    'Thursday': {
      'Breakfast': 'Upma, Banana, Sugar',
      'Lunch': 'Rice, Parippu, Pappadam, Thoran',
      'Dinner': 'Chapathi, Beef Curry / Soya Chunk Curry',
    },
    'Friday': {
      'Breakfast': 'Appam, Stew',
      'Lunch': 'Biriyani (Chicken/Veg), Raita, Pickle',
      'Dinner': 'Dosa, Tomato Chutney',
    },
    'Saturday': {
      'Breakfast': 'Poori, Potato Masala',
      'Lunch': 'Rice, Sambar, Pachadi, Kondattam',
      'Dinner': 'Ghee Rice, Chicken Fry / Gobi Manchurian',
    },
    'Sunday': {
      'Breakfast': 'Idiyappam, Egg Roast / Veg Stew',
      'Lunch': 'Meals, Payasam',
      'Dinner': 'Chapathi, Dal Fry',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Hostel Services',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF78909C),
          indicatorWeight: 3,
          labelColor: const Color(0xFF78909C),
          unselectedLabelColor: subtitleColor,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Mess Menu'),
            Tab(text: 'Complaints'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Mess Menu Tab
          ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: _messMenu.keys.length,
            itemBuilder: (context, index) {
              final day = _messMenu.keys.elementAt(index);
              final menu = _messMenu[day]!;
              final isToday = DateTime.now().weekday == (index + 1);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isToday
                        ? const Color(0xFF78909C)
                        : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.shade200),
                    width: isToday ? 2 : 1,
                  ),
                  boxShadow: [
                    if (isToday && !isDark)
                      BoxShadow(
                        color: const Color(0xFF78909C).withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                child: ExpansionTile(
                  initiallyExpanded: isToday,
                  shape: const Border(),
                  title: Row(
                    children: [
                      Text(
                        day,
                        style: GoogleFonts.poppins(
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isToday ? const Color(0xFF78909C) : textColor,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF78909C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Today',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF78909C),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          _MenuRow('Breakfast', menu['Breakfast']!, isDark),
                          const Divider(),
                          _MenuRow('Lunch', menu['Lunch']!, isDark),
                          const Divider(),
                          _MenuRow('Dinner', menu['Dinner']!, isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Complaints Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF78909C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF78909C).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF78909C),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Submit maintenance requests or hostel-related complaints here. The warden will review them.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Room Number',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. A-102',
                    hintStyle: GoogleFonts.poppins(color: subtitleColor),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Issue Type',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: cardColor,
                  style: GoogleFonts.poppins(color: textColor),
                  items: [
                    'Electrical',
                    'Plumbing',
                    'Carpentry',
                    'Cleaning',
                    'Internet',
                    'Other'
                  ]
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) {},
                  hint: Text(
                    'Select issue type',
                    style: GoogleFonts.poppins(color: subtitleColor),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 4,
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue in detail...',
                    hintStyle: GoogleFonts.poppins(color: subtitleColor),
                    filled: true,
                    fillColor: cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Complaint submitted successfully.',
                            style: GoogleFonts.poppins(),
                          ),
                          backgroundColor: const Color(0xFF78909C),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF78909C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Submit Complaint',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final String items;
  final bool isDark;

  const _MenuRow(this.title, this.items, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              items,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
