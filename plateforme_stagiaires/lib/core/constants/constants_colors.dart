import 'package:flutter/material.dart';

class ColorConstants {
  static const primary = Color.fromARGB(255, 23, 132, 221);

  static const secondary = Color(0xFF26A69A);

  static const accent = Color(0xFFFFC107);

  static const success = Color(0xFF4CAF50);

  static const warning = Color(0xFFFF9800);

  static const error = Color(0xFFE53935);
  static const splashColor = LinearGradient(
    colors: [Color(0xFF26A69A), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
