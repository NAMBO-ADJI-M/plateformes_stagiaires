import 'package:flutter/material.dart';
import 'package:plateforme_stagiaires/core/constants/constants_colors.dart';
import 'package:plateforme_stagiaires/features/home/carnet_page.dart';
import 'package:plateforme_stagiaires/features/home/covoiturage_page.dart';
import 'package:plateforme_stagiaires/features/home/home_page.dart';
import 'package:plateforme_stagiaires/features/home/notifications_page.dart';
import 'package:plateforme_stagiaires/features/home/profile_page.dart';
import 'package:plateforme_stagiaires/widgets/main_navigation_bar.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  static const _titles = [
    'Accueil',
    'Carnet',
    'Covoiturage',
    'Notifications',
    'Profil',
  ];

  final List<Widget> _pages = const [
    HomePage(),
    CarnetPage(),
    CovoituragePage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: ColorConstants.primary,
        elevation: 0,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: MainNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }
}
