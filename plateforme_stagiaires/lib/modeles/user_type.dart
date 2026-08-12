import 'package:flutter/material.dart';

enum UserType { stagiaire, entreprise }

extension UserTypeExtension on UserType {
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

  /// Rôle API (pour les requêtes)
  String get apiRole => this == UserType.stagiaire ? 'stagiaire' : 'entreprise';

  /// Routes
  String get dashboardRoute =>
      this == UserType.stagiaire ? '/stagiaire/dashboard' : '/entreprise/dashboard';

  String get profilRoute =>
      this == UserType.stagiaire ? '/stagiaire/profil' : '/entreprise/profil';

  /// Icônes
  String get iconName =>
      this == UserType.stagiaire ? 'assets/icons/stagiaire.svg' : 'assets/icons/entreprise.svg';

  IconData get materialIcon =>
      this == UserType.stagiaire ? Icons.school_outlined : Icons.business_outlined;

  IconData get materialIconFilled =>
      this == UserType.stagiaire ? Icons.school : Icons.business;

  /// Couleurs
  Color get color => this == UserType.stagiaire ? const Color(0xFF2563EB) : const Color(0xFF7C3AED);

  Color get lightColor =>
      this == UserType.stagiaire ? const Color(0xFFDBEAFE) : const Color(0xFFEDE9FE);

  /// Emoji
  String get emoji => this == UserType.stagiaire ? '🎓' : '🏢';

  /// Description
  String get description => this == UserType.stagiaire
      ? 'Étudiant ou apprenti en stage'
      : 'Structure d\'accueil ou tuteur de stage';

  /// Méthodes utilitaires
  bool get isStagiaire => this == UserType.stagiaire;
  bool get isEntreprise => this == UserType.entreprise;

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

  static List<UserType> get all => UserType.values;

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
