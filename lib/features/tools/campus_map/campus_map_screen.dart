// ===============================
// FILE NAME: campus_map_screen.dart
// FILE PATH: lib/features/tools/campus_map/campus_map_screen.dart
// ===============================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CampusMapScreen extends StatefulWidget {
  const CampusMapScreen({super.key});

  @override
  State<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends State<CampusMapScreen> {
  String _selectedCategory = 'All';
  String? _selectedBuilding;
  late final MapController _mapController;

  // Campus center (RIT Kottayam approximate coordinates)
  static const LatLng _campusCenter = LatLng(9.5833, 76.6167);

  // Building categories and data
  static final List<Map<String, dynamic>> _buildings = [
    {
      'name': 'Main Block',
      'category': 'Academic',
      'description': 'Administrative offices and main auditorium',
      'lat': 9.5835,
      'lng': 76.6170,
      'icon': Icons.business_rounded,
      'color': const Color(0xFF4FACFE),
    },
    {
      'name': 'CS Department',
      'category': 'Academic',
      'description': 'Computer Science & Engineering Department',
      'lat': 9.5838,
      'lng': 76.6165,
      'icon': Icons.computer_rounded,
      'color': const Color(0xFF4FACFE),
    },
    {
      'name': 'EC Department',
      'category': 'Academic',
      'description': 'Electronics & Communication Engineering',
      'lat': 9.5832,
      'lng': 76.6162,
      'icon': Icons.memory_rounded,
      'color': const Color(0xFF4FACFE),
    },
    {
      'name': 'ME Department',
      'category': 'Academic',
      'description': 'Mechanical Engineering Department',
      'lat': 9.5830,
      'lng': 76.6168,
      'icon': Icons.precision_manufacturing_rounded,
      'color': const Color(0xFF4FACFE),
    },
    {
      'name': 'Library',
      'category': 'Academic',
      'description': 'Central Library with digital resources',
      'lat': 9.5836,
      'lng': 76.6172,
      'icon': Icons.local_library_rounded,
      'color': const Color(0xFF7B61FF),
    },
    {
      'name': 'Boys Hostel',
      'category': 'Hostel',
      'description': 'Boys hostel complex',
      'lat': 9.5840,
      'lng': 76.6175,
      'icon': Icons.apartment_rounded,
      'color': const Color(0xFFFF9F1C),
    },
    {
      'name': 'Girls Hostel',
      'category': 'Hostel',
      'description': 'Girls hostel complex',
      'lat': 9.5828,
      'lng': 76.6175,
      'icon': Icons.apartment_rounded,
      'color': const Color(0xFFFF9F1C),
    },
    {
      'name': 'Cafeteria',
      'category': 'Facilities',
      'description': 'Main cafeteria and food court',
      'lat': 9.5834,
      'lng': 76.6160,
      'icon': Icons.restaurant_rounded,
      'color': const Color(0xFFF7971E),
    },
    {
      'name': 'Sports Complex',
      'category': 'Sports',
      'description': 'Indoor and outdoor sports facilities',
      'lat': 9.5842,
      'lng': 76.6158,
      'icon': Icons.sports_soccer_rounded,
      'color': const Color(0xFF43E97B),
    },
    {
      'name': 'Auditorium',
      'category': 'Facilities',
      'description': 'College auditorium for events',
      'lat': 9.5837,
      'lng': 76.6168,
      'icon': Icons.theater_comedy_rounded,
      'color': const Color(0xFFE040FB),
    },
    {
      'name': 'Parking Area',
      'category': 'Facilities',
      'description': 'Two-wheeler and four-wheeler parking',
      'lat': 9.5830,
      'lng': 76.6155,
      'icon': Icons.local_parking_rounded,
      'color': const Color(0xFF78909C),
    },
    {
      'name': 'Basketball Court',
      'category': 'Sports',
      'description': 'Open-air basketball court',
      'lat': 9.5844,
      'lng': 76.6163,
      'icon': Icons.sports_basketball_rounded,
      'color': const Color(0xFF43E97B),
    },
  ];

  static const List<String> _categories = [
    'All',
    'Academic',
    'Hostel',
    'Facilities',
    'Sports',
  ];

  static final Map<String, Color> _categoryColors = {
    'All': const Color(0xFF9983F3),
    'Academic': const Color(0xFF4FACFE),
    'Hostel': const Color(0xFFFF9F1C),
    'Facilities': const Color(0xFFF7971E),
    'Sports': const Color(0xFF43E97B),
  };

  List<Map<String, dynamic>> get _filteredBuildings {
    if (_selectedCategory == 'All') return _buildings;
    return _buildings
        .where((b) => b['category'] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
      body: Stack(
        children: [
          // --- MAP ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _campusCenter,
              initialZoom: 17.0,
              minZoom: 15.0,
              maxZoom: 19.0,
              onTap: (tapPosition, point) => setState(() => _selectedBuilding = null),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.enterit.app',
              ),
              MarkerLayer(
                markers: _filteredBuildings.map((building) {
                  final isSelected = _selectedBuilding == building['name'];
                  return Marker(
                    point: LatLng(building['lat'], building['lng']),
                    width: isSelected ? 52 : 42,
                    height: isSelected ? 52 : 42,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedBuilding = building['name']);
                        _mapController.move(
                          LatLng(building['lat'], building['lng']),
                          18.0,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: building['color'],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (building['color'] as Color)
                                  .withOpacity(0.4),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          building['icon'],
                          color: Colors.white,
                          size: isSelected ? 24 : 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // --- TOP BAR ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: textColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      'Campus Map',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- CATEGORY CHIPS ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  final color = _categoryColors[cat]!;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _selectedBuilding = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? color.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isSelected ? Colors.white : textColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- BUILDING INFO CARD (Bottom Sheet style) ---
          if (_selectedBuilding != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _BuildingInfoCard(
                building: _buildings.firstWhere(
                  (b) => b['name'] == _selectedBuilding,
                ),
                cardColor: cardColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                onClose: () => setState(() => _selectedBuilding = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _BuildingInfoCard extends StatelessWidget {
  final Map<String, dynamic> building;
  final Color cardColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onClose;

  const _BuildingInfoCard({
    required this.building,
    required this.cardColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = building['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(building['icon'], color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  building['name'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  building['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    building['category'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              color: subtitleColor,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
