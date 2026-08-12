import 'package:flutter/material.dart';
import '../../../core/constants/constants_colors.dart';
import 'dashboard_student_screen.dart';
import 'logbook_placeholder_screen.dart';
import 'progression_screen.dart';
import 'profile_student_screen.dart';

/// Coquille de navigation de l'espace stagiaire.
/// Onglets : Accueil / Logbook / Stats / Profil (cf. mockups dashboard-student,
/// progression-screen, profile-student).
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  final _pages = const [
    DashboardStudentScreen(),
    LogbookPlaceholderScreen(),
    ProgressionScreen(),
    ProfileStudentScreen(),
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
              icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined), label: 'Logbook'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Stats'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
