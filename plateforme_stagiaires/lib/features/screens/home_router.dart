import 'package:flutter/material.dart';
import 'package:plateforme_stagiaires/features/screens/student/student_shell.dart';
import 'package:plateforme_stagiaires/features/screens/tuteur/tuteur_shell.dart';
import 'package:plateforme_stagiaires/services/auth_service.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return FutureBuilder<void>(
      future: authService.loadToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return authService.isEntreprise ? const TuteurShell() : const StudentShell();
      },
    );
  }
}