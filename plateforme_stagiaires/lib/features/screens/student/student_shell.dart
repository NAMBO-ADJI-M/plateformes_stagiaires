import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/geofencing_service.dart';
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
  void initState() {
    super.initState();
    // Démarre le pointage automatique par géofencing si la permission
    // "toujours autoriser" est déjà accordée. Si elle ne l'est pas encore,
    // c'est la bannière du dashboard (_activerGeofencing) qui prendra le
    // relais une fois l'utilisateur activé la localisation.
    _initGeofencing();
  }

  Future<void> _initGeofencing() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) return;

      final carnets = await ApiService().getCarnets();
      if (carnets.isEmpty) return;

      final carnet = carnets.firstWhere(
        (c) => c['statut'] == 'EN_COURS',
        orElse: () => carnets.first,
      ) as Map<String, dynamic>;

      final lat = carnet['geofence_lat'];
      final lng = carnet['geofence_lng'];
      if (lat == null || lng == null) return;

      await GeofencingService().start(
        carnetId: carnet['id'] as String,
        lat: (lat as num).toDouble(),
        lng: (lng as num).toDouble(),
        rayonMetres: ((carnet['geofence_rayon'] ?? 100) as num).toInt(),
      );
    } catch (_) {
      // Pas bloquant : si le démarrage échoue (pas de réseau, pas de
      // carnet, etc.), le pointage manuel reste disponible dans l'app.
    }
  }

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