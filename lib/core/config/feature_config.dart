// ===============================
// FILE NAME: feature_config.dart
// FILE PATH: lib/core/config/feature_config.dart
// ===============================

import 'package:flutter/material.dart';

import 'package:my_project/features/campus/presentation/departments_screen.dart';
import 'package:my_project/features/campus/presentation/event_list_screen.dart';
import 'package:my_project/features/lost_and_found/presentation/lost_and_found_screen.dart';
import 'package:my_project/features/marketplace/presentation/marketplace_screen.dart';
import 'package:my_project/features/cafeteria/presentation/cafeteria_screen.dart';
import 'package:my_project/features/transport/presentation/bus_list_screen.dart';
import 'package:my_project/features/chat/presentation/peer_rooms_screen.dart';
import 'package:my_project/features/campus/presentation/id_card_screen.dart';
import 'package:my_project/features/tools/code_playground/code_playground_screen.dart';
import 'package:my_project/features/tools/community/dev_community_screen.dart';
import 'package:my_project/features/tools/games/games_hub_screen.dart';
import 'package:my_project/features/campus/presentation/etlab_webview_screen.dart';

// New Features Imports
import 'package:my_project/features/tools/gpa_calculator/gpa_calculator_screen.dart';
import 'package:my_project/features/tools/attendance_tracker/attendance_tracker_screen.dart';
import 'package:my_project/features/tools/exam_countdown/exam_countdown_screen.dart';
import 'package:my_project/features/tools/campus_map/campus_map_screen.dart';
import 'package:my_project/features/tools/study_planner/study_planner_screen.dart';
import 'package:my_project/features/tools/confession_box/confession_screen.dart';
import 'package:my_project/features/tools/alumni_connect/alumni_connect_screen.dart';
import 'package:my_project/features/tools/placement_prep/placement_prep_screen.dart';
import 'package:my_project/features/tools/hostel_services/hostel_services_screen.dart';
import 'package:my_project/features/tools/club_hub/club_hub_screen.dart';

class FeatureConfig {
  static final List<String> categories = [
    'All',
    'Campus',
    'Utilities',
    'Social',
    'Services',
    'Tech'
  ];

  static final Map<String, dynamic> featureMap = {
    // --- CAMPUS ---
    'departments': {
      'label': 'Departments',
      'description': 'Academic departments info',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF4FACFE),
      'screen': const DepartmentsScreen(),
      'category': 'Campus',
    },
    'events': {
      'label': 'Events',
      'description': 'Upcoming college events',
      'icon': Icons.calendar_month_rounded,
      'color': const Color(0xFF43E97B),
      'screen': const EventListScreen(),
      'category': 'Campus',
    },
    'digital_id': {
      'label': 'Digital ID',
      'description': 'Your virtual campus ID',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF89F7FE),
      'screen': const IdCardScreen(),
      'category': 'Campus',
    },
    'campus_map': {
      'label': 'Campus Map',
      'description': 'Navigate around campus',
      'icon': Icons.map_rounded,
      'color': const Color(0xFF2EC4B6),
      'screen': const CampusMapScreen(),
      'category': 'Campus',
    },
    'etlab': {
      'label': 'ETLab',
      'description': 'Campus management portal',
      'icon': Icons.computer_rounded,
      'color': const Color(0xFF3B2667),
      'screen': const EtlabWebviewScreen(),
      'category': 'Campus',
    },

    // --- UTILITIES ---
    'gpa_calculator': {
      'label': 'GPA Calc',
      'description': 'Calculate SGPA & CGPA',
      'icon': Icons.calculate_rounded,
      'color': const Color(0xFF7B61FF),
      'screen': const GpaCalculatorScreen(),
      'category': 'Utilities',
    },
    'attendance_tracker': {
      'label': 'Attendance',
      'description': 'Track your class presence',
      'icon': Icons.fact_check_rounded,
      'color': const Color(0xFF00B4D8),
      'screen': const AttendanceTrackerScreen(),
      'category': 'Utilities',
    },
    'exam_countdown': {
      'label': 'Exams',
      'description': 'Track upcoming exams',
      'icon': Icons.timer_rounded,
      'color': const Color(0xFFFF6B6B),
      'screen': const ExamCountdownScreen(),
      'category': 'Utilities',
    },
    'study_planner': {
      'label': 'Timetable',
      'description': 'Plan your weekly schedule',
      'icon': Icons.event_note_rounded,
      'color': const Color(0xFFFF9F1C),
      'screen': const StudyPlannerScreen(),
      'category': 'Utilities',
    },

    // --- SOCIAL ---
    'peer_rooms': {
      'label': 'Peer Rooms',
      'description': 'Join student voice rooms',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFF00C6FB),
      'screen': const PeerRoomsScreen(),
      'category': 'Social',
    },
    'confession_box': {
      'label': 'Confessions',
      'description': 'Share anonymously',
      'icon': Icons.chat_bubble_rounded,
      'color': const Color(0xFFE040FB),
      'screen': const ConfessionScreen(),
      'category': 'Social',
    },
    'club_hub': {
      'label': 'Club Hub',
      'description': 'Discover student clubs',
      'icon': Icons.diversity_3_rounded,
      'color': const Color(0xFFAB47BC),
      'screen': const ClubHubScreen(),
      'category': 'Social',
    },
    'alumni_connect': {
      'label': 'Alumni',
      'description': 'Connect with graduates',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF4ECDC4),
      'screen': const AlumniConnectScreen(),
      'category': 'Social',
    },
    'dev_community': {
      'label': 'Dev Community',
      'description': 'Tech forums and Q&A',
      'icon': Icons.forum_rounded,
      'color': const Color(0xFFF83600),
      'screen': const DevCommunityScreen(),
      'category': 'Social',
    },

    // --- SERVICES ---
    'marketplace': {
      'label': 'Marketplace',
      'description': 'Buy/sell student items',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFFFFD200),
      'screen': const MarketplaceScreen(),
      'category': 'Services',
    },
    'cafeteria': {
      'label': 'Cafeteria',
      'description': 'Canteen menu & orders',
      'icon': Icons.fastfood_rounded,
      'color': const Color(0xFFF7971E),
      'screen': const CafeteriaScreen(),
      'category': 'Services',
    },
    'hostel_services': {
      'label': 'Hostel',
      'description': 'Mess menu & complaints',
      'icon': Icons.apartment_rounded,
      'color': const Color(0xFF78909C),
      'screen': const HostelServicesScreen(),
      'category': 'Services',
    },
    'lost_and_found': {
      'label': 'Lost & Found',
      'description': 'Report or find items',
      'icon': Icons.search_rounded,
      'color': const Color(0xFFFA709A),
      'screen': const LostAndFoundScreen(),
      'category': 'Services',
    },
    'bus_tracker': {
      'label': 'Bus Tracker',
      'description': 'College bus routes & timings',
      'icon': Icons.directions_bus_rounded,
      'color': const Color(0xFF30CFD0),
      'screen': const BusListScreen(),
      'category': 'Services',
    },

    // --- TECH ---
    'code_lab': {
      'label': 'Code Lab',
      'description': 'Run code snippets live',
      'icon': Icons.code_rounded,
      'color': const Color(0xFF13547A),
      'screen': const CodePlaygroundScreen(),
      'category': 'Tech',
    },
    'placement_prep': {
      'label': 'Placement',
      'description': 'Aptitude & interview prep',
      'icon': Icons.work_rounded,
      'color': const Color(0xFFFF8A65),
      'screen': const PlacementPrepScreen(),
      'category': 'Tech',
    },
    'games': {
      'label': 'Games',
      'icon': Icons.sports_esports_rounded,
      'color': const Color(0xFFF72585), // Neon Pink
      'screen': const GamesHubScreen(),
      'category': 'Social',
      'description': 'Play games and compete on the college leaderboard.',
    },
    'nonote': {
      'label': 'No-Note',
      'description': 'Generate notes from PDF',
      'icon': Icons.note_alt_rounded,
      'color': const Color(0xFFDA22FF),
      'url': 'https://nonote.tech',
      'category': 'Tech',
    },
  };
}
