import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import 'dashboard_tuteur_screen.dart';
import 'liste_stagiaires_screen.dart';
import 'attestations_screen.dart';

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
    AttestationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.background,
      body: SafeArea(child: IndexedStack(index: _index, children: _pages)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ColorConstants.primary,
        unselectedItemColor: ColorConstants.textSecondary,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.groups_outlined),
              activeIcon: Icon(Icons.groups_rounded),
              label: 'Stagiaires'),
          BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: 'Attestations'),
        ],
      ),
    );
  }
}
