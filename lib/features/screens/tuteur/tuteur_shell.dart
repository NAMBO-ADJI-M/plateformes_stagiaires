import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/stagiaire_event_bus.dart';
import 'dashboard_tuteur_screen.dart';
import 'liste_stagiaires_screen.dart';
import 'attestations_screen.dart';
import 'recommander_screen.dart';
import 'profile_tuteur_screen.dart';

/// Coquille de navigation de l'espace tuteur.
class TuteurShell extends StatefulWidget {
  const TuteurShell({super.key});

  @override
  State<TuteurShell> createState() => _TuteurShellState();
}

class _TuteurShellState extends State<TuteurShell> {
  int _index = 0;
  int _availableCount = 0;
  StreamSubscription? _stagiaireSub;

  final List<Widget> _pages = [
    const DashboardTuteurScreen(),
    const ListeStagiairesScreen(),
    const AttestationsScreen(),
    const RecommanderScreen(),
    const ProfileTuteurScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _stagiaireSub = StagiaireEventBus().onAvailableCountChanged.listen((count) {
      if (mounted) setState(() => _availableCount = count);
    });
    
    _fetchInitialCount();
  }

  Future<void> _fetchInitialCount() async {
    try {
      final res = await ApiService().getEntrepriseStagiaires();
      final Map<String, dynamic> data = res;
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
        items: [
          const BottomNavigationBarItem(
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
          const BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: 'Attestations'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.thumb_up_alt_outlined),
              activeIcon: Icon(Icons.thumb_up_alt_rounded),
              label: 'Recommander'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profil'),
        ],
      ),
    );
  }
}
