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
}
