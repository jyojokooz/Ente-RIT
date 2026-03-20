// ===============================
// FILE NAME: overlay_text_model.dart
// FILE PATH: lib/screens/stories/overlay_text_model.dart
// ===============================

import 'package:flutter/material.dart';

enum OverlayType { text, sticker }

class OverlayItem {
  final String id;
  final OverlayType type;
  String content; // Stores text or the emoji/sticker string
  Offset offset;
  double scale;
  double rotation;
  Color color;

  OverlayItem({
    required this.id,
    required this.type,
    required this.content,
    required this.offset,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
  });
}
