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
import 'package:my_project/features/tools/games/game_view_screen.dart';
import 'package:my_project/features/campus/presentation/etlab_webview_screen.dart';

class FeatureConfig {
  static final Map<String, dynamic> featureMap = {
    'departments': {
      'label': 'Departments',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF4FACFE),
      'screen': const DepartmentsScreen(),
    },
    'events': {
      'label': 'Events',
      'icon': Icons.calendar_month_rounded,
      'color': const Color(0xFF43E97B),
      'screen': const EventListScreen(),
    },
    'lost_and_found': {
      'label': 'Lost & Found',
      'icon': Icons.search_rounded,
      'color': const Color(0xFFFA709A),
      'screen': const LostAndFoundScreen(),
    },
    'marketplace': {
      'label': 'Marketplace',
      'icon': Icons.storefront_rounded,
      'color': const Color(0xFFFFD200),
      'screen': const MarketplaceScreen(),
    },
    'cafeteria': {
      'label': 'Cafeteria',
      'icon': Icons.fastfood_rounded,
      'color': const Color(0xFFF7971E),
      'screen': const CafeteriaScreen(),
    },
    'bus_tracker': {
      'label': 'Bus Tracker',
      'icon': Icons.directions_bus_rounded,
      'color': const Color(0xFF30CFD0),
      'screen': const BusListScreen(),
    },
    'peer_rooms': {
      'label': 'Peer Rooms',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFF00C6FB),
      'screen': const PeerRoomsScreen(),
    },
    'digital_id': {
      'label': 'Digital ID',
      'icon': Icons.badge_rounded,
      'color': const Color(0xFF89F7FE),
      'screen': const IdCardScreen(),
    },
    'code_lab': {
      'label': 'Code Lab',
      'icon': Icons.code_rounded,
      'color': const Color(0xFF13547A),
      'screen': const CodePlaygroundScreen(),
    },
    'dev_community': {
      'label': 'Dev Community',
      'icon': Icons.forum_rounded,
      'color': const Color(0xFFF83600),
      'screen': const DevCommunityScreen(),
    },
    'games': {
      'label': 'Games',
      'icon': Icons.sports_esports_rounded,
      'color': const Color(0xFF00CDAC),
      'screen': const GameViewScreen(
        title: 'Smash Karts',
        url: 'https://poki.com/en/g/smash-karts',
      ),
    },
    'etlab': {
      'label': 'ETLab',
      'icon': Icons.computer_rounded,
      'color': const Color(0xFF3B2667),
      'screen': const EtlabWebviewScreen(),
    },
    'nonote': {
      'label': 'No-Note',
      'icon': Icons.note_alt_rounded,
      'color': const Color(0xFFDA22FF),
      'url': 'https://nonote.tech',
    },
  };
}
