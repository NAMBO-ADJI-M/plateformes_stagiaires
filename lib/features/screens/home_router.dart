import 'package:flutter/material.dart';
import 'package:plateforme_stagiaires/features/screens/student/entreprise_search_screen.dart';
import 'package:plateforme_stagiaires/features/screens/student/student_shell.dart';
import 'package:plateforme_stagiaires/features/screens/tuteur/tuteur_shell.dart';
import 'package:plateforme_stagiaires/services/auth_service.dart';
import 'package:plateforme_stagiaires/services/internship_service.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final internshipService = InternshipService();

    return FutureBuilder<void>(
      future: authService.loadToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (authService.isEntreprise) {
          return const TuteurShell();
        }

        // Pour les stagiaires, on vérifie s'ils ont au moins un rattachement
        return FutureBuilder<Map<String, dynamic>>(
          future: internshipService.checkRattachementStatus(),
          builder: (context, statusSnapshot) {
            if (statusSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            if (statusSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Erreur de connexion au serveur.'),
                ),
              );
            }

            final hasRattachement =
                statusSnapshot.data?['has_rattachement'] ?? false;

            if (!hasRattachement) {
              return const EntrepriseSearchScreen(isMandatory: true);
            }

            return const StudentShell();
          },
        );
      },
    );
  }
}
