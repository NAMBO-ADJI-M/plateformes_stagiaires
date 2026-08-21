import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/stagiaire_event_bus.dart';
import 'dashboard_tuteur_screen.dart';
import 'liste_stagiaires_screen.dart';
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
  int _availableCount = 0;
  StreamSubscription? _stagiaireSub;

  final _pages = const [
    DashboardTuteurScreen(),
    ListeStagiairesScreen(),
    AttestationsScreen(),
    ProfileTuteurScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _stagiaireSub = StagiaireEventBus().onAvailableCountChanged.listen((count) {
      if (mounted) setState(() => _availableCount = count);
    });
    
    // Premier chargement silencieux du nombre de stagiaires disponibles
    _fetchInitialCount();
  }

  Future<void> _fetchInitialCount() async {
    try {
      final res = await ApiService().getEntrepriseStagiaires();
      final Map<String, dynamic> data = res as Map<String, dynamic>;
      final disponibles = data['disponibles'] as List<dynamic>?;
      if (mounted) {
        setState(() => _availableCount = disponibles?.length ?? 0);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stagiaireSub?.cancel();
    super.dispose();
  }

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
              icon: Badge(
                label: Text('$_availableCount'),
                isLabelVisible: _availableCount > 0,
                child: const Icon(Icons.groups_outlined),
              ),
              activeIcon: Badge(
                label: Text('$_availableCount'),
                isLabelVisible: _availableCount > 0,
                child: const Icon(Icons.groups_rounded),
              ),
              label: 'Stagiaires'),
          BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: 'Attestations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
        ],
      ),
    );
  }
}
