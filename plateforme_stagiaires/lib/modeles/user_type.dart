import 'package:flutter/material.dart';

enum UserType {
  stagiaire,
  entreprise,
}

extension UserTypeExtension on UserType {
  // ============================================
  // GETTERS EXISTANTS
  // ============================================

  String get label {
    switch (this) {
      case UserType.stagiaire:
        return 'Stagiaire';
      case UserType.entreprise:
        return 'Entreprise';
    }
  }

  String get subtitle {
    switch (this) {
      case UserType.stagiaire:
        return 'Accédez à votre espace stagiaire';
      case UserType.entreprise:
        return 'Accédez à l’espace entreprise';
    }
  }

  // ============================================
  // NOUVEAUX GETTERS
  // ============================================

  /// Rôle API (pour les requêtes)
  String get apiRole {
    switch (this) {
      case UserType.stagiaire:
        return 'stagiaire';
      case UserType.entreprise:
        return 'entreprise';
    }
  }

  /// Route de redirection vers le dashboard
  String get dashboardRoute {
    switch (this) {
      case UserType.stagiaire:
        return '/stagiaire/dashboard';
      case UserType.entreprise:
        return '/entreprise/dashboard';
    }
  }

  /// Route de redirection vers le profil
  String get profilRoute {
    switch (this) {
      case UserType.stagiaire:
        return '/stagiaire/profil';
      case UserType.entreprise:
        return '/entreprise/profil';
    }
  }

  /// Icône associée au type
  String get iconName {
    switch (this) {
      case UserType.stagiaire:
        return 'assets/icons/stagiaire.svg';
      case UserType.entreprise:
        return 'assets/icons/entreprise.svg';
    }
  }

  /// Icône Material Design
  IconData get materialIcon {
    switch (this) {
      case UserType.stagiaire:
        return Icons.school_outlined;
      case UserType.entreprise:
        return Icons.business_outlined;
    }
  }

  /// Icône Material Design (version remplie)
  IconData get materialIconFilled {
    switch (this) {
      case UserType.stagiaire:
        return Icons.school;
      case UserType.entreprise:
        return Icons.business;
    }
  }

  /// Couleur associée
  Color get color {
    switch (this) {
      case UserType.stagiaire:
        return Color(0xFF2563EB); // Bleu
      case UserType.entreprise:
        return Color(0xFF7C3AED); // Violet
    }
  }

  /// Couleur de fond (version light)
  Color get lightColor {
    switch (this) {
      case UserType.stagiaire:
        return Color(0xFFDBEAFE); // Bleu clair
      case UserType.entreprise:
        return Color(0xFFEDE9FE); // Violet clair
    }
  }

  /// Emoji associé
  String get emoji {
    switch (this) {
      case UserType.stagiaire:
        return '🎓';
      case UserType.entreprise:
        return '🏢';
    }
  }

  /// Description longue
  String get description {
    switch (this) {
      case UserType.stagiaire:
        return 'Étudiant ou apprenti en stage';
      case UserType.entreprise:
        return 'Structure d\'accueil ou tuteur de stage';
    }
  }

  // ============================================
  // MÉTHODES UTILITAIRES
  // ============================================

  /// Vérifier si le type est stagiaire
  bool get isStagiaire => this == UserType.stagiaire;

  /// Vérifier si le type est entreprise
  bool get isEntreprise => this == UserType.entreprise;

  /// Convertir un rôle API en UserType
  static UserType fromApiRole(String role) {
    switch (role) {
      case 'stagiaire':
        return UserType.stagiaire;
      case 'entreprise':
        return UserType.entreprise;
      default:
        throw ArgumentError('Rôle inconnu: $role');
    }
  }

  /// Obtenir les deux types en liste
  static List<UserType> get all => UserType.values;

  /// Obtenir les options pour un Select
  static List<DropdownMenuItem<UserType>> get dropdownItems {
    return all.map((type) {
      return DropdownMenuItem(
        value: type,
        child: Row(
          children: [
            Icon(type.materialIcon, color: type.color),
            const SizedBox(width: 8),
            Text(type.label),
          ],
        ),
      );
    }).toList();
  }

}
