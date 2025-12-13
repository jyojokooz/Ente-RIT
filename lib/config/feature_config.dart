// ===============================
// FILE NAME: feature_config.dart
// FILE PATH: lib/config/feature_config.dart
// ===============================

import 'package:flutter/material.dart';

// Import all your feature screens here
import '../screens/departments_screen.dart';
import '../screens/event_list_screen.dart';
import '../screens/lost_and_found_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/cafeteria_screen.dart';
import '../screens/bus_list_screen.dart';
import '../screens/ai_chat_history_screen.dart';
import '../screens/peer_rooms_screen.dart';
import '../screens/id_card_screen.dart';
import '../screens/code_playground_screen.dart';
import '../screens/dev_community_screen.dart';
import '../screens/quiz_categories_screen.dart';
import '../screens/pdf_buddy_screen.dart';
import '../screens/resume_analyzer_screen.dart';
import '../screens/youtube_summarizer_screen.dart';
import '../screens/tech_news_screen.dart';
import '../screens/game_view_screen.dart';
import '../screens/etlab_webview_screen.dart';

class FeatureConfig {
  // This map links a unique String ID to the visual and functional aspects of the feature.
  // The 'screen' property is used for navigation.
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
    'connect_ai': {
      'label': 'Connect AI',
      'icon': Icons.auto_awesome_rounded,
      'color': const Color(0xFF667EEA),
      'screen': const AiChatHistoryScreen(),
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
    'quiz': {
      'label': 'Quiz',
      'icon': Icons.quiz_rounded,
      'color': const Color(0xFFB721FF),
      'screen': const QuizCategoriesScreen(),
    },
    'pdf_buddy': {
      'label': 'PDF Buddy',
      'icon': Icons.picture_as_pdf_rounded,
      'color': const Color(0xFFF5576C),
      'screen': const PdfBuddyScreen(),
    },
    'resume_ai': {
      'label': 'Resume AI',
      'icon': Icons.description_rounded,
      'color': const Color(0xFF0BA360),
      'screen': const ResumeAnalyzerScreen(),
    },
    'yt_summary': {
      'label': 'YT Summary',
      'icon': Icons.play_circle_filled_rounded,
      'color': const Color(0xFFFF0844),
      'screen': const YouTubeSummarizerScreen(),
    },
    'tech_news': {
      'label': 'Tech News',
      'icon': Icons.newspaper_rounded,
      'color': const Color(0xFF203A43),
      'screen': const TechNewsScreen(),
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
