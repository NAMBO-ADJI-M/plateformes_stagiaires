import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import 'dashboard_tuteur_screen.dart';
import 'liste_stagiaires_screen.dart';
import 'suivi_placeholder_screen.dart';
import 'attestations_screen.dart';
import 'profile_tuteur_screen.dart';

/// Coquille de navigation de l'espace tuteur.
/// Onglets : Dashboard / Stagiaires / Suivi / Attestations / Profil
/// (cf. mockups dashboard-tuteur, liste-stagiaires, attestation-screen).
class TuteurShell extends StatefulWidget {
  const TuteurShell({super.key});

  @override
  State<TuteurShell> createState() => _TuteurShellState();
}

class _TuteurShellState extends State<TuteurShell> {
  int _index = 0;

  final _pages = const [
    DashboardTuteurScreen(),
    ListeStagiairesScreen(),
    SuiviPlaceholderScreen(),
    AttestationsScreen(),
    ProfileTuteurScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: SafeArea(child: _pages[_index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ColorConstants.primary,
        unselectedItemColor: ColorConstants.textSecondary,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined), label: 'Stagiaires'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), label: 'Suivi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              label: 'Attestations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}