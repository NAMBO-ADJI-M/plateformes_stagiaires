import 'package:flutter/material.dart';

class ColorConstants {
<<<<<<< HEAD
  // Couleurs principales
  static const primary = Color(0xFF1E3A8A); // Indigo profond
  static const primaryLight = Color(0xFF3B82F6); // Bleu vif
  static const primaryDark = Color(0xFF1E1B4B); // Dark Indigo
  
  static const secondary = Color(0xFF0D9488); // Teal élégant
  static const secondaryLight = Color(0xFF14B8A6);
  
  static const accent = Color(0xFF8B5CF6); // Violet moderne
  static const accentOrange = Color(0xFFF97316); // Orange vif

  // Couleurs de statut
  static const success = Color(0xFF10B981); // Vert menthe
  static const warning = Color(0xFFF59E0B); // Ambre
  static const error = Color(0xFFEF4444); // Rouge corail
  static const info = Color(0xFF06B6D4); // Cyan

  // Surfaces & Fonds
  static const background = Color(0xFFF8FAFC); // Slate clair
  static const cardBackground = Colors.white;
  static const darkBackground = Color(0xFF0F172A);
  static const darkCardBackground = Color(0xFF1E293B);
  
  // Textes
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);

  // Gradients modernes
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const splashColor = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Ombre subtile et élégante
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.3),
      blurRadius: 20,
      spreadRadius: 2,
      offset: const Offset(0, 4),
    ),
  ];

}

=======
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
>>>>>>> dea45cde37182e685a97536d5e5cdb8b04665f0e
