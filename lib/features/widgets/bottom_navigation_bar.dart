import 'package:flutter/material.dart';
import '../screens/student/home_screen.dart';
import '../screens/student/carnet_screen.dart';
import '../screens/student/covoiturage_home_screen.dart';
import '../screens/student/notifications_screen.dart';
import '../screens/student/profile_student_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      HomeScreen(
        onNavigateToPointage: () => setState(() => selectedIndex = 1),
        onNavigateToCarnet: () => setState(() => selectedIndex = 1),
        onNavigateToTrajet: () => setState(() => selectedIndex = 2),
        onNavigateToProfil: () => setState(() => selectedIndex = 4),
      ),
      const CarnetScreen(),
      const CovoiturageHomeScreen(),
      const NotificationsScreen(),
      const ProfileStudentScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: "Accueil",
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: "Carnet",
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: "Covoiturage",
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: "Notifications",
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
    );
  }
}