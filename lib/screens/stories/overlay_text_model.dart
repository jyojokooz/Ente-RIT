// ===============================
// FILE NAME: overlay_text_model.dart
// FILE PATH: lib/screens/stories/overlay_text_model.dart
// ===============================

import 'package:flutter/material.dart';

class OverlayText {
  String text;
  Offset offset;
  double scale;
  double rotation;
  Color color;

  OverlayText({
    required this.text,
    required this.offset,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
  });
}
